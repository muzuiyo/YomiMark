script_name = "YomiMark Furigana"
script_description = "Add furigana to subtitles using YomiMark API"
script_author = "YomiMark"
script_version = "1.3.6"  -- 增强 Normal 模式匹配逻辑，优化 KTV 分隔符

require "karaskel"
local json = require("json")
local request = require("luajit-request")

-- Default settings
local DEFAULT_API_URL = "https://api.yomimark.lain.today"

-- Furigana settings
local rubyscale = 0.5
local rubypadding = 0

-- ============================================================
-- utils
-- ============================================================

local function table_copy(t)
    local r = {}
    for k, v in pairs(t) do
        r[k] = v
    end
    return r
end

local function utf8_chars(str)
    local chars = {}
    local i = 1
    while i <= #str do
        local c = str:byte(i)
        local step = 1
        if c >= 0xF0 then step = 4
        elseif c >= 0xE0 then step = 3
        elseif c >= 0xC0 then step = 2 end
        chars[#chars+1] = str:sub(i, i+step-1)
        i = i + step
    end
    return chars
end

local function remove_ass_tags(str)
    return str:gsub("{[^}]*}", "")
end

local function extract_pos(text)
    local x, y = text:match("\\pos%((%d+),(%d+)%)")
    if x and y then
        return tonumber(x), tonumber(y)
    end
    return nil, nil
end

-- 为字符串中**每个字符**前添加 {\k0} (用于获取每个字符的位置)
local function add_k0_before_text(s)
    local chars = utf8_chars(s)
    local result = {}
    for _, ch in ipairs(chars) do
        result[#result+1] = "{\\k0}" .. ch
    end
    return table.concat(result)
end

-- ============================================================
-- API Communication
-- ============================================================

local function call_api(api_url, text)
    local request_body = json.encode({
        text = text,
        mode = "furigana",
        to = "hiragana"
    })

    local response = request.send(api_url, {
        method = "POST",
        data = request_body,
        headers = {["Content-Type"] = "application/json"}
    })

    if not response or response.code ~= 200 then
        aegisub.log("API error\n")
        return nil
    end

    local ok, result = pcall(json.decode, response.body)
    if not ok or result.error then
        aegisub.log("API response error\n")
        return nil
    end
    return result.result
end

-- ============================================================
-- KTV converter (符合用户规范：每个假名后用 #|< 分隔)
-- 示例： "夜|<よ#|<る" "今|<き#|<ょ日|<う#|<は"
-- ============================================================
local function convert_to_ktv(api_result)
    local output = {}
    local pos = 1
    
    while pos <= #api_result do
        local ruby_start = api_result:find("<ruby>", pos, true)
        if not ruby_start then
            output[#output+1] = api_result:sub(pos)
            break
        end
        
        if ruby_start > pos then
            output[#output+1] = api_result:sub(pos, ruby_start-1)
        end
        
        local ruby_end = api_result:find("</ruby>", ruby_start, true)
        if not ruby_end then
            output[#output+1] = api_result:sub(ruby_start)
            break
        end
        
        local ruby_content = api_result:sub(ruby_start+6, ruby_end-1)
        local kanji = ruby_content:match("^(.-)<rp>")
        local furigana = ruby_content:match("<rt>(.-)</rt>")
        
        if kanji and furigana then
            local kc = utf8_chars(kanji)
            local fc = utf8_chars(furigana)
            
            if #kc == 1 then
                -- 单个汉字：将每个假名用 #|< 连接
                local furi_str = table.concat(fc, "#|<")
                output[#output+1] = kc[1] .. "|<" .. furi_str
            else
                -- 多个汉字：将假名均匀分配到每个汉字上，每个假名后跟 #|<
                local k_count = #kc
                local f_count = #fc
                local base = math.floor(f_count / k_count)
                local remainder = f_count % k_count
                local idx = 1
                for i = 1, k_count do
                    local take = base + (i <= remainder and 1 or 0)
                    local furi_parts = {}
                    for j = 1, take do
                        if idx <= f_count then
                            furi_parts[#furi_parts+1] = fc[idx]
                            idx = idx + 1
                        end
                    end
                    local furi_str = table.concat(furi_parts, "#|<")
                    output[#output+1] = kc[i] .. "|<" .. furi_str
                end
            end
        else
            output[#output+1] = ruby_content
        end
        
        pos = ruby_end + 7
    end
    
    return table.concat(output)
end

-- ============================================================
-- UI
-- ============================================================

local function show_dialog()
    local dialog = {
        {class="label", x=0,y=0,label="API URL:"},
        {class="edit", x=1,y=0,width=2,name="api_url",value=DEFAULT_API_URL},
        {class="label", x=0,y=1,label="Mode:"},
        {class="dropdown", x=1,y=1,width=2,name="mode",
         items={"KTV (Karaoke Template)","Normal (Ruby)"},
         value="KTV (Karaoke Template)"}
    }
    local pressed, res = aegisub.dialog.display(dialog, {"OK","Cancel"})
    if pressed ~= "OK" then return nil end
    return {
        api_url = res.api_url,
        mode = res.mode:find("KTV") and "ktv" or "normal"
    }
end

-- ============================================================
-- MAIN
-- ============================================================

local function process(subtitles, selected_lines)
    local config = show_dialog()
    if not config then return end

    local meta, styles = karaskel.collect_head(subtitles)

    if config.mode == "ktv" then
        for _, i in ipairs(selected_lines) do
            local line = subtitles[i]
            local text = line.text

            -- 分离 ASS 标签和纯文本
            local segments = {}
            local pos = 1
            while pos <= #text do
                local s = text:find("{", pos)
                if not s then
                    segments[#segments+1] = {type="text", content=text:sub(pos)}
                    break
                end
                if s > pos then
                    segments[#segments+1] = {type="text", content=text:sub(pos, s-1)}
                end
                local e = text:find("}", s)
                if not e then
                    segments[#segments+1] = {type="text", content=text:sub(s)}
                    break
                end
                segments[#segments+1] = {type="tag", content=text:sub(s, e)}
                pos = e+1
            end

            local final = ""
            for _, seg in ipairs(segments) do
                if seg.type == "tag" then
                    final = final .. seg.content
                else
                    local api_result = call_api(config.api_url, seg.content)
                    if api_result then
                        final = final .. convert_to_ktv(api_result)
                    else
                        final = final .. seg.content
                    end
                end
            end

            line.text = final
            subtitles[i] = line
        end
        aegisub.set_undo_point("YomiMark Furigana")
        return
    end

    -- =========================
    -- NORMAL MODE (改进匹配逻辑)
    -- =========================

    local function parse_ruby_html(html)
        local rubies = {}
        local kanji_text = ""
        local pos = 1
        while pos <= #html do
            local ruby_start = html:find("<ruby>", pos, true)
            if not ruby_start then
                kanji_text = kanji_text .. html:sub(pos)
                break
            end
            kanji_text = kanji_text .. html:sub(pos, ruby_start-1)
            local ruby_end = html:find("</ruby>", ruby_start, true)
            if not ruby_end then
                kanji_text = kanji_text .. html:sub(ruby_start)
                break
            end
            local ruby_content = html:sub(ruby_start+6, ruby_end-1)
            local kanji = ruby_content:match("^(.-)<rp>")
            local furigana = ruby_content:match("<rt>(.-)</rt>")
            if kanji and furigana then
                kanji_text = kanji_text .. kanji
                rubies[#rubies+1] = {kanji=kanji, furigana=furigana}
            else
                kanji_text = kanji_text .. ruby_content
            end
            pos = ruby_end + 7
        end
        return {kanji_text=kanji_text, rubies=rubies}
    end

    local function distribute_furigana(kanji_str, furigana_str)
        local kc = utf8_chars(kanji_str)
        local fc = utf8_chars(furigana_str)
        local result = {}
        local k_count = #kc
        local f_count = #fc
        if k_count == 0 then return {} end
        local base = math.floor(f_count / k_count)
        local rem = f_count % k_count
        local idx = 1
        for i = 1, k_count do
            local take = base + (i <= rem and 1 or 0)
            local seg = {}
            for j = 1, take do
                if idx <= f_count then
                    seg[#seg+1] = fc[idx]
                    idx = idx + 1
                end
            end
            result[i] = table.concat(seg)
        end
        return result
    end

    for _, sel_i in ipairs(selected_lines) do
        local original_line = subtitles[sel_i]
        local raw_text = original_line.text

        local pos_x, pos_y = extract_pos(raw_text)
        local plain_text = remove_ass_tags(raw_text)
        if plain_text == "" then
            aegisub.log("Line %d: empty text after removing tags, skipping.\n", sel_i)
            goto continue
        end

        local api_result = call_api(config.api_url, plain_text)
        if not api_result then
            aegisub.log("Line %d: API failed, keeping original.\n", sel_i)
            goto continue
        end

        local parsed = parse_ruby_html(api_result)
        local final_text = parsed.kanji_text
        local rubies = parsed.rubies

        -- 构建“需要注音的汉字”列表（保持顺序）
        local ruby_chars = {}  -- 每个元素 {furigana}
        for _, ruby in ipairs(rubies) do
            local kanji_chars = utf8_chars(ruby.kanji)
            local furi_dist = distribute_furigana(ruby.kanji, ruby.furigana)
            for i = 1, #kanji_chars do
                table.insert(ruby_chars, {char=kanji_chars[i], furigana=furi_dist[i] or ""})
            end
        end

        -- 创建基础行（只包含最终文本，保留 \pos）
        local new_line = table_copy(original_line)
        local line_text = final_text
        if pos_x and pos_y then
            line_text = string.format("{\\pos(%d,%d)}%s", pos_x, pos_y, final_text)
        end
        new_line.text = line_text
        new_line.effect = "furi-fx"
        subtitles[sel_i] = new_line

        -- 获取每个字符的精确位置
        local vl = table_copy(new_line)
        local pure_text = final_text
        vl.text = add_k0_before_text(pure_text)
        if pos_x and pos_y then
            vl.text = string.format("{\\pos(%d,%d)}%s", pos_x, pos_y, vl.text)
        end
        karaskel.preproc_line(subtitles, meta, styles, vl)

        if not vl.kara or #vl.kara == 0 then
            aegisub.log("Line %d: karaskel produced no syllables.\n", sel_i)
            goto continue
        end

        local all_chars = utf8_chars(final_text)
        local ruby_index = 1
        local style_obj = styles[original_line.style]
        local stylefs = style_obj and style_obj.fontsize or 40  -- 默认字号
        local furi_fontsize = stylefs * rubyscale

        -- 顺序匹配：遍历所有字符，按顺序匹配需要注音的汉字
        for char_pos = 1, #all_chars do
            if ruby_index > #ruby_chars then break end
            local current_char = all_chars[char_pos]
            local target = ruby_chars[ruby_index]
            if current_char == target.char then
                local k = vl.kara[char_pos]
                if k then
                    local rlx = vl.left + k.center
                    local rly = vl.top - (furi_fontsize / 2) - rubypadding
                    local furi_line = table_copy(new_line)
                    furi_line.text = string.format("{\\an5\\fs%d\\pos(%d,%d)}%s",
                        furi_fontsize, rlx, rly, target.furigana)
                    furi_line.effect = "furi-fx"
                    subtitles.append(furi_line)
                end
                ruby_index = ruby_index + 1
            end
            -- 如果不是需要注音的汉字，则跳过（不生成注音）
        end

        if ruby_index <= #ruby_chars then
            aegisub.log("Warning: Line %d: not all ruby chars were placed (missing %d)\n", sel_i, #ruby_chars - ruby_index + 1)
        end

        ::continue::
    end

    aegisub.log("Normal mode: processed %d lines\n", #selected_lines)
    aegisub.set_undo_point("YomiMark Furigana")
end

aegisub.register_macro(script_name, script_description, process)