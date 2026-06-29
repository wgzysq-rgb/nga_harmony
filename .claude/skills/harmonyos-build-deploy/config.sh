# HarmonyOS 构建部署 — 可配置常量
# 如需适配本机环境，修改此文件中的变量即可

# DevEco Studio 安装目录
DEVECO_STUDIO_HOME="C:/Program Files/Huawei/DevEco Studio"

# 工具路径
HVIGORW="${DEVECO_STUDIO_HOME}/tools/hvigor/bin/hvigorw.bat"
EMULATOR="${DEVECO_STUDIO_HOME}/tools/emulator/Emulator.exe"
NODE="${DEVECO_STUDIO_HOME}/tools/node/node.exe"

# SDK 环境变量（hvigorw 构建必需）
export DEVECO_SDK_HOME="${DEVECO_STUDIO_HOME}/sdk"

# Git Bash 路径转换保护（避免 MSYS 将 /data/... 误转为 C:/Program Files/Git/data/...）
export MSYS_NO_PATHCONV=1

# 模拟器实例名（来自 Emulator.exe -list 输出）
EMULATOR_INSTANCE="Huawei_TripleFold"

# 应用信息
BUNDLE_NAME="com.example.nga_oh"
ABILITY_NAME="EntryAbility"

# HAP 输出路径（相对于项目根目录）
HAP_PATH="entry/build/default/outputs/default/entry-default-signed.hap"

# 构建模式：debug | release
BUILD_MODE="debug"
