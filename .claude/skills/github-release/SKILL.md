---
name: github-release
description: 通用 GitHub Release 发布工具。将任意文件上传到 GitHub Releases，自动打标签并创建 Release。
---

# GitHub Release 发布

三步完成：**打标签推送 → 创建 Release 上传文件**

## 用法

```bash
source .claude/skills/github-release/config.sh
```

### 参数

| 参数 | 必填 | 说明 |
|------|------|------|
| 版本号 | ✅ | 如 `v1.0.0`、`v2.3.4-beta` |
| 文件路径 | ✅ | 要上传的文件的本地路径 |
| Release 说明 | ❌ | 自定义说明，不填则用默认模板 |

---

## 步骤 1：打标签并推送

```bash
source .claude/skills/github-release/config.sh

TAG="<版本号>"  # 例如: v1.0.0

git tag "$TAG"
git push "${GIT_REMOTE}" "$TAG"
```

> 如果标签已存在，先删除再重建：
> ```bash
> git tag -d "$TAG"
> git push "${GIT_REMOTE}" ":refs/tags/$TAG"
> ```

## 步骤 2：创建 Release 并上传文件

### 方式 A：gh CLI（推荐）

```bash
source .claude/skills/github-release/config.sh

TAG="<版本号>"
FILE="<文件路径>"    # 例如: dist/app-release.apk
NOTES="<Release 说明>"  # 可选

gh release create "$TAG" \
  --title "$TAG" \
  --notes "$NOTES" \
  "$FILE"
```

上传多个文件：

```bash
gh release create "$TAG" \
  --title "$TAG" \
  --notes "$NOTES" \
  file1.zip \
  file2.apk
```

### 方式 B：Chrome MCP（gh CLI 不可用时）

通过 `mcp__chrome-devtools` 工具在浏览器中操作：

```bash
# 1. 打开新建 Release 页面（标签已推送的前提下）
mcp__chrome-devtools__new_page \
  url="https://github.com/<owner>/<repo>/releases/new?tag=$TAG"

# 2. 填写标题
mcp__chrome-devtools__fill \
  uid="<标题输入框 uid>" \
  value="$TAG"

# 3. 填写说明
mcp__chrome-devtools__fill \
  uid="<说明文本框 uid>" \
  value="<Release 说明>"

# 4. 上传文件
mcp__chrome-devtools__upload_file \
  uid="<文件选择按钮 uid>" \
  filePath="<文件路径>"   # ⚠️ 参数名是 filePath（驼峰），不是 file_path

# 5. 点击发布
mcp__chrome-devtools__click \
  uid="<发布按钮 uid>"
```

> **注意**：`upload_file` 的第二个参数名是 `filePath`（小驼峰），不要写成 `file_path`（下划线），否则会报 schema validation 错误。

---

## 典型使用场景

### 发布鸿蒙 HAP

```bash
source .claude/skills/github-release/config.sh

TAG="v1.0.0"
FILE="entry/build/default/outputs/default/entry-default-unsigned.hap"
NOTES="> ⚠️ **HarmonyOS 不能直接安装 .hap 文件包**，需要使用签名工具自行签名。

详见 README 中的安装说明。"

git tag "$TAG" && git push origin "$TAG" && \
gh release create "$TAG" --title "$TAG" --notes "$NOTES" "$FILE"
```

---

## 踩坑记录

| 问题 | 原因 | 解决 |
|------|------|------|
| `gh` CLI 未认证 | 未登录 GitHub | 执行 `gh auth login` |
| tag 已存在 | 本地或远程已有同名标签 | `git tag -d \$TAG && git push origin :refs/tags/\$TAG` |
| `gh` command not found | 未安装 GitHub CLI | 从 https://cli.github.com/ 下载安装 |
| Release 说明包含特殊字符 | Shell 变量展开冲突 | 用单引号包裹 `--notes` 内容，或写入文件再 `--notes-file notes.md` |
| MCP `upload_file` 报 schema validation 错误 | 参数名用了 `file_path`（下划线） | 参数名必须是 `filePath`（驼峰） |
| MCP 上传时浏览器文件选择器不认 `.hap` 后缀 | GitHub 的 accept 列表不含 `.hap` | 先用 JS 给文件输入框的 accept 属性加上 `.hap`，或临时重命名为 `.zip` 上传后再改回 `.hap` |
