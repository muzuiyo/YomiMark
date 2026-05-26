# YomiMark Aegisub 插件

为 Aegisub 字幕编辑器提供自动日语注音功能的插件。支持 KTV 字幕和普通字幕的注音标注。

## 功能概述

### KTV 字幕注音
为符合 Kara Template 格式的字幕自动添加注音，与卡拉 OK 模板自动化工具和样式制作工具无缝集成，轻松制作专业 KTV 注音字幕。

### 普通字幕注音
为常规字幕添加 Ruby 注音标注，自动处理日文汉字并生成平假名、片假名或罗马字注音。

## 安装步骤

### 前置要求

- **Aegisub** 字幕编辑器（推荐版本 3.2.2 及以上）
- **Visual C++ Runtime** （某些系统可能需要）
- 下载对应版本的 **libcurl.dll**

### 第一步：下载 libcurl.dll

1. 根据你的 Aegisub 版本选择对应的 libcurl.dll：
   - **32 位版本 (x86)** - 如果使用 32 位 Aegisub
   - **64 位版本 (x64)** - 如果使用 64 位 Aegisub

   > **重要提示**：请确保下载的 libcurl 版本与 Aegisub 架构一致，否则插件无法正常工作。

2. 你可以从以下地方获取 libcurl.dll：
   - [libcurl 官方网站](https://curl.se/download.html)
   - 或从其他可靠的第三方来源

### 第二步：放置 libcurl.dll

1. 将下载的 `libcurl.dll` 复制到 **Aegisub 安装目录的根目录**
   
   路径示例：
   ```
   C:\Program Files (x86)\Aegisub\          # Windows 32-bit
   C:\Program Files\Aegisub\                # Windows 64-bit
   /Applications/Aegisub.app/Contents/MacOS/  # macOS
   /usr/local/bin/                          # Linux
   ```

### 第三步：复制 include 文件夹

1. 在插件所在目录找到 `include` 文件夹
   
2. 将其内容复制到 Aegisub 的自动化脚本目录：
   ```
   Aegisub安装目录/automation/include/
   ```

   完整路径应如下所示：
   ```
   C:\Program Files (x86)\Aegisub\automation\include\
   ```

### 第四步：安装插件脚本

1. 将 `furigana_kara.lua` 文件复制到 Aegisub 的自动化脚本目录：

   ```
   Aegisub\automation\autoload\
   ```

2. 重启 Aegisub，插件将自动加载

### 验证安装

1. 打开 Aegisub
2. 进入菜单 **Automation** → 确认列表中出现 **YomiMark Furigana**
3. 如果出现，说明安装成功！

## 使用方法

### 基本步骤

1. **打开字幕文件** - 在 Aegisub 中打开日文字幕文件（.ass 或 .ssa 格式）

2. 选择需要添加注音的字幕行

3. **运行插件** - 进入菜单 **Automation** → **YomiMark Furigana**

4. **配置设置** - 点击后，会弹出配置对话框：
   - **模式选择**：选择注音模式
   - **API 地址**：输入或选择 API 服务地址

5. **处理结果** - 等待处理完成，插件会自动更新字幕行

### 模式说明

插件在首次运行时会弹出模式选择窗口，你可以选择以下注音模式：

#### KTV 模式（Kara Template）
- 适用于已使用 Kara Template 格式的字幕
- 自动识别并保留模板标签
- 在对应位置添加注音
- 完全兼容卡拉 OK 模板自动化工具

#### 普通模式（Ruby）
- 适用于常规字幕文件
- 会添加普通的注音字幕

### API 地址配置

插件支持两种 API 地址选择方式：

#### 官方公共 API
```
https://api.yomimark.lain.today
```
- **优点**：无需部署，开箱即用
- **缺点**：不保证稳定性和服务可用性
- **适用场景**：快速体验、临时使用

#### 本地或自托管 API
```
http://127.0.0.1:8787
http://your-domain.com
```
- **优点**：完全控制，稳定可靠
- **缺点**：需要自行搭建 YomiMark 后端服务
- **适用场景**：生产环境、长期使用

#### 修改 API 地址
- 运行时：在弹出的配置窗口中输入地址
- 手动编辑：修改 Lua 脚本中的 `DEFAULT_API_URL` 常量

## 使用示例

### 示例 1：处理 KTV 字幕

-- 假设有如下带 Kara Template 的字幕行：

```
[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: K2-furigana,Resource Han Rounded JP,60,&H00FFFFFF,&H00FF0000,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,2,0,3,30,120,40,1
Style: K1-furigana,Resource Han Rounded JP,60,&H00FFFFFF,&H00FF0000,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,2,0,1,120,30,220,1
Style: K1,Resource Han Rounded JP,120,&H00FFFFFF,&H00FF0000,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,4,0,1,120,30,220,1
Style: K2,Resource Han Rounded JP,120,&H00FFFFFF,&H00FF0000,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,4,0,3,30,120,40,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Comment: 0,0:00:00.00,0:00:00.00,K1,,0,0,0,code once,remember("color_table", {}); remember("default_color", "&HFF0000&"); remember("style_table", {K1=true,K2=true});
Comment: 0,0:00:00.00,0:00:00.00,K1,,0,0,0,code once,function get_color(actor) local color=recall("color_table")[actor]; if not color then color=recall("default_color"); end return color; end
Comment: 0,0:00:00.00,0:00:00.00,K1,,0,0,0,code syl all,fxgroup.kara=syl.inline_fx=="" and (not not recall("style_table")[line.styleref.name])
Comment: 1,0:00:00.00,0:00:00.00,K1,overlay,0,0,0,template syl noblank all fxgroup kara,!retime("line",0,0)!{\pos($center,$middle)\an5\shad0\1c!get_color(line.actor)!\3c&HFFFFFF&\clip(!$sleft-3!,0,!$sleft-3!,1080)\t($sstart,$send,\clip(!$sleft-3!,0,!$sright+3!,1080))\bord5}
Comment: 0,0:00:00.00,0:00:00.00,K1,,0,0,0,template syl all fxgroup kara,!retime("line",0,0)!{\pos($center,$middle)\an5}
Comment: 1,0:00:00.00,0:00:00.00,K1,overlay,0,0,0,template furi all,!retime("line",-0,0)!{\pos($center,!$middle+10!)\an5\shad0\1c!get_color(line.actor)!\3c&HFFFFFF&\clip(!$sleft-3!,0,!$sleft-3!,1080)\t($sstart,$send,\clip(!$sleft-3!,0,!$sright+3!,1080))\bord5}
Comment: 0,0:00:00.00,0:00:00.00,K1,,0,0,0,template furi all,!retime("line",0,0)!{\pos($center,!$middle+10!)\an5}
Comment: 0,0:00:00.00,0:00:00.00,K1,music,0,0,0,template fx no_k,!retime("line",0,0)!{\pos($center,!$middle!)\an5\1c&H505050&\3c&HFFFFFFF&}
Dialogue: 0,0:00:25.41,0:00:30.41,Default,,0,0,0,,高速で過ぎ去った連続する情報
```

选中字幕行，设置样式为 KTV 样式（K1 或 K2）（该步骤可以使用 [Set Karaoke Style 自动化工具](https://github.com/MichiyamaKaren/aegisub-set-karaoke-style)），按照 KTV 模式分字，运行该自动化工具，再在注音符和后续文本之间进行分字，再运行“应用 KTV 模板”的自动化工具，即可生成按文字滚动的带注音 KTV 字幕。分字之间的 k 值可根据需要调整。

![演示动画](https://github.com/muzuiyo/YomiMark/blob/8a4a0b4f2919ba701fcefaa7c7dda06645ca24f1/docs/screen.gif)

### 示例 2：处理普通字幕

使用前确保字幕样式已从样式库添加到当前字幕文件，否则会弹出警告 `WARNING: Style not found`。

原始字幕：

![原始字幕截图](https://github.com/muzuiyo/YomiMark/blob/8a4a0b4f2919ba701fcefaa7c7dda06645ca24f1/docs/before.png)

处理后的注音字幕：

![注音字幕截图](https://github.com/muzuiyo/YomiMark/blob/8a4a0b4f2919ba701fcefaa7c7dda06645ca24f1/docs/after.png)

