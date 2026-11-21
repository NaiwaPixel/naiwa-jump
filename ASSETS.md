# 素材与第三方说明

本仓库的 GPL-3.0-only 程序许可适用于 kol-mm 和贡献者有权授权的原创程序部分，不改写第三方条款，也不替角色形象、图片、音频或商标作授权保证。

| 内容 | 来源与说明 |
| --- | --- |
| `assets/image/naiwa.png` | 原游戏已定稿的奶蛙 16 帧动作图 |
| `assets/image/skins/` | 9 套既有服装与 16 套新增服装；提示词、来源文件名、图集和校验值在 `art/` 中 |
| `assets/image/ui/` | 内置 image_gen 辅助制作的动物浮台和按钮；具体提示词与采用范围见 `art/ui-assets.json` |
| `assets/audio/` | 由 `dev-tools/generate-audio.py` 程序合成的本项目音频，没有引入第三方采样 |
| `docs/media/` | 游戏宣传图、图标及实际运行截图，包含 AI 辅助制作的美术 |
| `assets/Fonts/FusionPixel.ttf` | TakWolf 的 Fusion Pixel 12px Prop zh_hans，字体内部版本 2026.02.27，OFL-1.1 |

角色、美术、名称及商标保留各自权利。可以在这里查看制作与程序实现；拟将素材用于其他作品或商业用途时，应另行核实具体权利与授权。没有单项明确授权的素材，不视为采用 GPL。

## Fusion Pixel

Copyright (c) 2022, TakWolf (https://takwolf.com), with Reserved Font Name "Fusion Pixel".

本仓库保留字体原始二进制与内部版权信息，并附 [完整 OFL-1.1 文本](assets/Fonts/LICENSE-OFL.txt)。

- [字体上游](https://github.com/TakWolf/fusion-pixel-font)
- [上游许可证](https://github.com/TakWolf/fusion-pixel-font/blob/master/LICENSE-OFL)

`assets/Fonts/FusionPixel.xml` 引用官方运行环境的 Twemoji 字体后备项；后备字体二进制未打包进本仓库。MiSans、UrhoX、`urhox-libs` 及官方开发包由 Maker 环境提供，适用各自的授权与平台条款。
