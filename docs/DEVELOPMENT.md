# 开发与运行

本仓库是《像素奶蛙跳一跳》0.4.1 的独立 GitHub 源码快照。实际玩法代码、运行图片、音频和图集没有为此次上传重新制作；逐文件记录见 [source-snapshot.json](source-snapshot.json)。

## 接入自己的 Maker 项目

开发使用的官方工具版本为 `@taptap/maker@0.0.41`，运行入口为 `scripts/main.lua` 中的 `Start()`。普通 Lua 解释器只能运行规则测试，不能渲染完整游戏。

1. 安装 Git、Node.js 和 Python，准备自己的 [TapTap 制造](https://maker.taptap.cn/) 账号。
2. 在独立空目录运行 `npx --yes @taptap/maker@0.0.41 init`，按官方流程登录并选择自己的项目。确实需要另建游戏时，在官方选项中选择“创建新项目”。初始化会准备对应的官方引擎资料和依赖。
3. 将本仓库的 `scripts/` 和 `assets/` 复制到该项目；使用前先备份已有同名文件。参考 `.project/settings.json`、`.project/resources.json` 合并运行配置，并将入口设为 `main.lua`。
4. 保留自己项目的 `project_id`、账号绑定和发布配置，不用本仓库的可移植示例覆盖整份绑定配置。
5. 在已初始化项目中执行以下命令。替换示例路径为自己的目录。

```sh
npx --yes @taptap/maker@0.0.41 preview status --target-dir /path/to/your-maker-project --json
npx --yes @taptap/maker@0.0.41 preview start --target-dir /path/to/your-maker-project --json
```

已有试玩窗口时先使用现有窗口。关闭试玩后才运行官方验证，避免两者争用运行时：

```sh
npx --yes @taptap/maker@0.0.41 preview validate --target-dir /path/to/your-maker-project --mode both --screenshot-frame 1800 --validate-frames 1850 --validate-timeout 140 --validate-test Tests/gameplay.lua --width 540 --height 960 --json
```

发布到 TapTap 应使用官方 Maker 构建和审核流程。向本 GitHub 仓库提交代码不会自动更新线上游戏。

## 不依赖 Maker 的规则测试

```sh
python -m pip install -r requirements-test.txt
python tests/run_model.py
```

结果写入被 Git 忽略的 `.test-runs/model-rules.json`。运行器会自行创建目录，适用于刚克隆的项目。[`ci/gameplay-rules.yml`](../ci/gameplay-rules.yml) 提供使用 Python 3.12 和同一份依赖的 GitHub Actions 模板。有工作流写入权限的维护者可以将它移至 `.github/workflows/ci.yml` 以启用自动检查。

## 素材维护

运行所需的图片、字体、音频、裁切坐标及碰撞轮廓均已包含，无需重新生成。

- `dev-tools/generate-audio.py` 使用标准 Python 库重新生成合成音频。
- `dev-tools/read-platform-masks.py` 读取已有 PNG 的透明度并生成碰撞数据，需要 Pillow。
- `dev-tools/build-costume-preview.py` 是历史服装预览生成器，输出到原工作区的 `交付/` 目录。
- `dev-tools/import-costumes.py` 保留原制作流程供维护者参考，依赖《奶蛙的结合》原始图集及原制作工作区，不属于公开版运行或测试的前置步骤。`art/` 中的生成文件已改为仓库内相对路径，并保留原始生成文件名；重新导入前需由维护者指定实际外部源文件，不能直接把已导入的文件复制到自身。

仓库没有包含 Maker 引擎、官方 SDK 副本、私人发布回执、授权缓存、开发者账号 ID 或本机 Git 历史。公开配置不会绑定到工作室的线上项目。

## 贡献

提交问题时描述平台、复现步骤、预期结果和实际表现；可附截图或录屏。涉及动作、形象或碰撞的修改请保留前后对照。Pull Request 应运行规则测试；游戏完整运行和 TapTap 发布需要维护者在官方环境继续验证。
