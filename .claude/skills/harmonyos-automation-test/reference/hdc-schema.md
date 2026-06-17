# HDC 接口规格

定义 `hdc` / `hidumper` / `uitest` / `Emulator.exe` 命令的输入参数与返回结构。

## 0. 通用类型

| 类型名 | 文本编码 | 含义 |
|---|---|---|
| `int` | 十进制整数字面量 | 像素坐标、ID、计数 |
| `float` | 十进制浮点字面量 | 几何尺寸、系数 |
| `bool` | `"true"` \| `"false"` | 布尔（字符串形式） |
| `string` | UTF-8 | 文本 |
| `Bounds` | `[x1,y1][x2,y2]`，四 `int` | 矩形，(x1,y1) 左上，(x2,y2) 右下，单位像素 |
| `Color#` | `#AARRGGBB`（8 位十六进制） | AA 透明度，RRGGBB 色通道 |
| `ColorRGBA` | `RGBA-0xRRGGBB, colorSpace: <cs>` | RRGGBB 色通道；`cs` ∈ `DISPLAY_P3` 等 |
| `enum` | 限定字符串集 | 枚举值 |

环境前置：

```
DEVECO_SDK_HOME = C:/Program Files/Huawei/DevEco Studio/sdk
MSYS_NO_PATHCONV = 1   # 仅 Git Bash
```

---

## 1. Emulator.exe

可执行路径：`tools/emulator/Emulator.exe`

### 1.1 `-list`
- 输入：无
- 输出（stdout）：每行一个实例名

### 1.2 `-list -details`
- 输入：无
- 输出（stdout）：JSON 数组，元素字段：

| 字段 | 类型 | 含义 |
|---|---|---|
| `name` | string | 实例名 |
| `isRunning` | `"true"`\|`"false"` | 运行状态 |
| `deviceModel` | string | 设备型号 |
| `deviceType` | string | 形态（`triplefold`/`phone`/…） |
| `hw.lcd.single.width/height` | int | 单屏分辨率 |
| `hw.lcd.double.width/height` | int | 双屏分辨率 |
| `hw.lcd.triple.width/height` | int | 三屏分辨率 |
| `hw.lcd.density` | int | 屏幕密度 |
| `hw.cpu.arch` | string | CPU 架构 |
| `hw.cpu.ncore` | int | CPU 核数 |
| `hw.ramSize` | int | 内存 MB |
| `os.apiVersion` | int | API 版本 |
| `os.osVersion` | string | 系统版本 |
| `instancePath` | string | 实例目录 |
| `isHotBoot` | `"true"`\|`"false"` | 热启动标志 |

### 1.3 `-start <name>`
- 输入：`name: string`
- 输出：阻塞；运行期持续向 stdout 输出日志
- 生命周期：进程退出 ⇒ 实例关闭

### 1.4 `-stop <name>`
- 输入：`name: string`
- 输出（stdout）：停止确认

---

## 2. hdc 设备/应用

### 2.1 `hdc list targets`
- 输入：无
- 输出（stdout）：`<ip>:<port>`（每行一个设备）；无设备时输出 `[Empty]`

### 2.2 `hdc install [-r] <hap>`
- 输入：`-r` 覆盖安装；`hap: path`
- 输出（stdout）：`install bundle successfully` 或错误信息

### 2.3 `hdc shell aa start -a <ability> -b <bundle>`
- 输入：`ability: string`，`bundle: string`
- 输出（stdout）：`start ability successfully`

### 2.4 `hdc shell pidof <name>`
- 输入：`name: string`（进程/包名）
- 输出（stdout）：PID

### 2.5 `hdc shell param get <key>`
- 输入：`key: string`
- 输出（stdout）：键值；`const.product.model` 返回 `emulator` 表示就绪

### 2.6 `hdc file recv <remote> <local>` / `send <local> <remote>`
- 输入：设备路径、本地路径
- 注：本地参数用相对文件名，避免正斜杠盘符被拼接

---

## 3. uitest dumpLayout

命令：`hdc shell uitest dumpLayout -p <remote_path>`

- 输入：`remote_path: string`（设备上 JSON 输出路径）
- 输出：JSON 文件，结构如下

### 3.1 结构

```
RootNode := { "attributes": Attributes, "children": Node[] }
Node     := { "attributes": Attributes, "children": Node[] }
```

### 3.2 `Attributes` 字段

| 字段 | 类型 | 含义 |
|---|---|---|
| `type` | enum | 组件类型，见 3.3 |
| `id` | string | 组件 id |
| `key` | string | 组件 key |
| `hashcode` | string | 哈希码（形如 `34:32`） |
| `accessibilityId` | string | 无障碍 id |
| `hierarchy` | string | 层级路径（形如 `ROOT34,0,0,0`） |
| `text` | string | 显示文本 |
| `originalText` | string | 原始文本 |
| `description` | string | 无障碍描述 |
| `hint` | string | 提示文本 |
| `bounds` | Bounds | 当前矩形 |
| `origBounds` | Bounds | 原始矩形 |
| `clickable` | bool | 可点击 |
| `longClickable` | bool | 可长按 |
| `checkable` | bool | 可勾选 |
| `checked` | bool | 已勾选 |
| `selected` | bool | 已选中 |
| `enabled` | bool | 可用 |
| `scrollable` | bool | 可滚动 |
| `focused` | bool | 已聚焦 |
| `visible` | bool | 可见 |
| `opacity` | float | 不透明度 |
| `clip` | bool | 裁剪 |
| `blur` | string | 模糊参数 |
| `zIndex` | int | 层级 |
| `backgroundColor` | Color# | 背景色 |
| `backgroundImage` | string | 背景图来源 |
| `pagePath` | string | 页面路径 |
| `bundleName` | string | 包名 |
| `abilityName` | string | Ability 名 |
| `hostWindowId` | string | 宿主窗口 id |
| `displayId` | string | 显示屏 id |
| `hitTestBehavior` | enum | 命中测试行为，见 3.4 |

### 3.3 `type` 枚举（已观测）

`Text` | `Image` | `Button` | `Row` | `Column` | `Stack` | `__Common__`

### 3.4 `hitTestBehavior` 枚举

`HitTestMode.Default` | `HitTestMode.Block` | `HitTestMode.Transparent` | `HitTestMode.None`

---

## 4. hidumper -s RenderService -a client

命令：`hdc shell hidumper -s RenderService -a 'client'`

- 输入：无（dump 全部客户端节点树）
- 输出（stdout）：文本，按 `pid[<int>]` 分段，每节点一行

### 4.1 节点行字段

| 字段 | 类型 | 含义 |
|---|---|---|
| NodeType | enum | 节点类型，见 4.2 |
| 节点 id | int | 节点实例 id（紧跟 NodeType 后方括号） |
| `parent` | int | 父节点 id；`18446744073709551615` 表示无父 |
| `instanceId` | int | 实例 id |
| `UIContext` | int | UI 上下文 id |
| `frameNodeId` | int | 关联的 ArkUI FrameNode id |
| `frameNodeTag` | string | 关联的 ArkUI 组件标签（`root`/`page`/`Column`/`Row`/`ListItem`/…） |
| `extendModifierIsDirty` | bool | modifier 脏标记 |
| `isNodeGroup` | bool | 节点组 |
| `isSingleFrameComposer` | bool | 单帧合成 |
| `isSuggestOpincNode` | bool | 预测性优化节点 |
| `isUifirstNode` | bool | UI 优先节点 |
| `drawRegion` | string\|`null` | 绘制区域 |
| `outOfParent` | int | 父外标志 |
| `hybridRenderCanvas` | bool | 混合渲染画布 |
| `animations` | list | 动画列表 |
| `modifiers` | list<Prop> | 样式属性列表，见 4.3 |

### 4.2 NodeType 枚举

`SurfaceNode` | `RootNode` | `CanvasNode`

### 4.3 `modifiers` Prop

格式：`<PropName>[<value>]`，多个以逗号分隔，整体包于 `modifiers[...]`。

PropName 枚举（已观测）：

`BackgroundColor` | `BorderColor` | `BorderStyle` | `BorderWidth` | `BorderDashWidth` | `BorderDashGap` | `Bounds` | `Frame` | `CornerRadius` | `ClipToFrame` | `ClipToBounds` | `Scale` | `Pivot` | `XY` | `PositionZ` | `PositionZApplicableCamera3d` | `Path` | `Region` | `EnvForegroundColor` | `ForegroundBlurMaskColor` | `TextBlob` | `GlyphID` | `Id` | `Name` | `NodeTag` | `NodeGroup` | `ModifierIsDirty` | `SingleFrameComposer` | `SuggestOpincNode` | `UifirstNode` | `RenderCanvas` | `CmdList` | `OPITEM` | `Pt`

Prop value 编码：

| PropName | value 编码 |
|---|---|
| `Bounds` / `Frame` | `x:<float> y:<float> z:<float> w:<float>`（z=宽，w=高） |
| `BackgroundColor` | `RGBA-0xRRGGBB, colorSpace: <cs>` |
| `CornerRadius` | `<float>` 或多元组 |
| `ClipToFrame` / `NodeGroup` 等 | bool |
| `PositionZ` / `Scale` | float |

---

## 5. uitest uiInput

命令：`hdc shell uitest uiInput <action> <args...>`

| 动作 | 参数 | 取值 |
|---|---|---|
| `click` | `x:int y:int` | 坐标 |
| `doubleClick` | `x:int y:int` | 坐标 |
| `longClick` | `x:int y:int` | 坐标 |
| `swipe` | `fx:int fy:int tx:int ty:int [velocity:int]` | velocity ∈ [200,40000]，默认 600 |
| `drag` | `fx:int fy:int tx:int ty:int [velocity:int]` | 同上 |
| `fling` | `fx:int fy:int tx:int ty:int [velocity:int] [stepLength:int]` | |
| `dircFling` | `direction:int [velocity:int] [stepLength:int]` | direction ∈ {0:左,1:右,2:上,3:下} |
| `keyEvent` | `key0 [<key1> [key2]]` | `Back`\|`Home`\|`Power`\|keyID |
| `inputText` | `x:int y:int text:string` | 在坐标处输入 |
| `text` | `text:string` | 在已聚焦处输入 |

底层注入：`hdc shell uinput`（参数见 `uinput --help`）。

---

## 6. snapshot_display

命令：`hdc shell snapshot_display -f <remote_path>`

- 输入：`remote_path: string`（JPEG 输出路径）
- 输出：JPEG 二进制文件；stdout 含 `width`、`height`、`pixel format` 元信息

---

## 7. hilog

命令：`hdc shell hilog`

- 输入：流式，可管道 `grep` / `timeout`
- 输出（stdout）：日志行流；每行含时间戳、PID、tag、级别、消息

按进程过滤：`hdc shell hilog | grep " <pid> "`。

---

## 8. hidumper 资源

### 8.1 `hidumper --net [pid]`
- 输入：`pid: int`（可选；省略则全系统）
- 输出字段：

| 字段 | 类型 | 含义 |
|---|---|---|
| `Received Bytes` | int | 累计接收字节数 |
| `Sent Bytes` | int | 累计发送字节数 |

### 8.2 `hidumper --mem [pid]`
- 输入：`pid: int`；可选 `--prune`、`--show-ashmem`、`--show-dmabuf`
- 输出：`[memory]` 表，列（单位 kB）：

`Pss Total` | `Shared Clean` | `Shared Dirty` | `Private Clean` | `Private Dirty` | `Swap Total` | `SwapPss` | `Heap Size` | `Heap Alloc` | `Heap Free`

按分类分行（`GL` 等）。

### 8.3 `hidumper --cpuusage [pid]`
- 输入：`pid: int`（可选）
- 输出：

| 字段 | 类型 | 含义 |
|---|---|---|
| `Load average` | float×3 | 1/5/15 分钟平均负载 |
| `Total` | float% | 总 CPU 占用 |
| `User Space` | float% | 用户态 |
| `Kernel Space` | float% | 内核态 |
| `iowait` | float% | IO 等待 |
| `irq` | float% | 中断 |
| `idle` | float% | 空闲 |

进程明细列：`PID` | `Total Usage` | `User Space` | `Kernel Space` | `Page Fault Minor` | `Page Fault Major` | `Name`

---

## 9. hidumper -s RenderService -a <perf>

| `-a` 值 | 输入 | 输出 |
|---|---|---|
| `fps` | `[windowname:string]` | 该窗口帧率统计 |
| `fpsCount` | 无 | 刷新率计数 |
| `hitchs` | `[windowname:string]` | 该窗口卡顿信息 |
| `surface` | 无 | 所有 surface 信息（用于取 windowname） |
| `RSTree` | 无 | RS 树 |
| `MultiRSTrees` | 无 | 多 RS 树 |
| `allInfo` | 无 | 全部信息 |

`windowname` 可由 `surface` 或 `client` 输出中的 `name[...]` 取得。

---

## 10. hidumper -e（faultlog）

| 命令 | 输入 | 输出 |
|---|---|---|
| `hidumper -e --list [process] [-n num] [--since ts] [--until ts]` | 进程名/数量/时间区间 | 异常退出记录列表 |
| `hidumper -e --print [process] [-n num] [--since ts] [--until ts]` | 同上 | faultlog 正文 |
| `hidumper -e --print <record_id>` | 记录 id | 指定记录正文 |

`ts`：时间戳。

---

## 11. hidumper 网络服务

### 11.1 `hidumper -s NetConnManager`
- 输入：无
- 输出：`Net connect Info` 段，字段：

| 字段 | 类型 | 含义 |
|---|---|---|
| `SupplierId` | int | 供应商标识 |
| `NetId` | int | 网络标识 |
| `ConnStat` | int | 连接状态 |
| `IsAvailable` | int | 可用标志 |
| `IsRoaming` | int | 漫游标志 |
| `Strength` | int | 信号强度 |
| `Frequency` | int | 频率 |
| `LinkUpBandwidthKbps` | int | 上行带宽 |
| `LinkDownBandwidthKbps` | int | 下行带宽 |
| `Uid` | int | 用户 id |

并含 `Dns result Info` 段：`netId`、`totalReports`、`failReports`。

### 11.2 `hidumper -s WifiDevice -a '-h'`
- dump 选项：`[-h]`（仅帮助）

---

## 12. hidumper 服务索引

### 12.1 `hidumper -ls`
- 输入：无
- 输出（stdout）：SystemAbility 列表，每行一个或多个 SA 名/id

### 12.2 `hidumper -s <SA> [-a '<args>']`
- 输入：`SA: string`（服务名或 id）；`-a` 后接该服务的 dump 参数
- 输出：该服务 dump 文本
