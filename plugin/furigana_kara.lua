script_name = "YomiMark Furigana"
script_description = "Add furigana to subtitles using YomiMark API"
script_author = "YomiMark"
script_version = "1.1.0"

local json = require("json")
local request = require("luajit-request")

-- Default settings
local DEFAULT_API_URL = "http://127.0.0.1:8787"

-- Furigana settings
local RUBBIFY_FONT_SIZE = 12
local RUBBIFY_PADDING = 2

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
        headers = {
            ["Content-Type"] = "application/json"
        }
    })

    if not response then
        aegisub.log("API error: No response\n")
        return nil
    end

    if response.code ~= 200 then
        aegisub.log("API error: HTTP %d\n", response.code)
        return nil
    end

    local success, result = pcall(json.decode, response.body)
    if not success then
        aegisub.log("Failed to parse API response\n")
        return nil
    end

    if result.error then
        aegisub.log("API error: %s\n", result.error)
        return nil
    end

    return result.result
end

-- ============================================================
-- KTV converter
-- ============================================================

local function utf8_chars(str)
    local chars = {}
    local i = 1
    while i <= #str do
        local c = str:byte(i)
        local len = 1
        if c >= 0xF0 then len = 4
        elseif c >= 0xE0 then len = 3
        elseif c >= 0xC0 then len = 2 end

        chars[#chars+1] = str:sub(i, i+len-1)
        i = i + len
    end
    return chars
end

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
                output[#output+1] = kc[1] .. "|<"
                for i,v in ipairs(fc) do
                    output[#output+1] = v
                    if i < #fc then output[#output+1] = "#|<" end
                end
            else
                local fpi = math.ceil(#fc / #kc)
                local idx = 1

                for i=1,#kc do
                    output[#output+1] = kc[i] .. "|<"
                    local c = 0
                    while idx <= #fc and c < fpi do
                        output[#output+1] = fc[idx]
                        idx = idx + 1
                        c = c + 1
                        if c < fpi and idx <= #fc then
                            output[#output+1] = "#|<"
                        end
                    end
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

    if config.mode == "ktv" then

        for _, i in ipairs(selected_lines) do
            local line = subtitles[i]
            local text = line.text

            local segments = {}
            local pos = 1

            while pos <= #text do
                local s = text:find("{", pos)
                if not s then
                    segments[#segments+1] = {type="text", content=text:sub(pos)}
                    break
                end

                if s > pos then
                    segments[#segments+1] = {type="text", content=text:sub(pos,s-1)}
                end

                local e = text:find("}", s)
                if not e then
                    segments[#segments+1] = {type="text", content=text:sub(s)}
                    break
                end

                segments[#segments+1] = {type="tag", content=text:sub(s,e)}
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

    else
        -- =========================
        -- NORMAL MODE (NEW)
        -- =========================

        local new_lines = {}

        for _, i in ipairs(selected_lines) do
            local line = subtitles[i]
            local api_result = call_api(config.api_url, line.text)

            if api_result then
                for furigana in api_result:gmatch("<rt>(.-)</rt>") do
                    local nl = table_copy(line)
                    nl.text = furigana
                    nl.effect = ""
                    table.insert(new_lines, nl)
                end
            end
        end

        for _, nl in ipairs(new_lines) do
            subtitles.append(nl)
        end

        aegisub.log("Normal mode: created %d furigana lines\n", #new_lines)
    end

    aegisub.set_undo_point("YomiMark Furigana")
end

aegisub.register_macro(script_name, script_description, process)