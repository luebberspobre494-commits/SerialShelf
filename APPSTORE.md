# SerialShelf — App Store 材料

> 这份文件随工程一起交付。**差异化说明答不满，就不该做这个 App。**

## 一句话定位

给那些说明书早扔了、又必须留着序列号的人：拍一张标签照片，序列号和保修期就存下来了。

## 差异化说明（4.3 闸门）

竞品扫描结论：

```
node tools/store-check.mjs --terms "serial number inventory" --cc us
→ verdict: OPEN
   22 个同概念 App，评分中位数 227，近 12 个月仅 1 个新进入者
   头部是 eBay Motors（汽车交易，不相干）、Sortly（团队库存，重）
→ 存档: store-checks/serial-number-inventory-us-2026-11-03.json
```

**1. 现有 App 漏掉了谁？**

两类现有产品都不服务个人：**Sortly / SmartLabels** 是给中小团队做仓库盘点的，有账号、有云同步、按座位收费；**备忘录和 Excel** 谁都能用，但序列号是"三年后要拿出来给客服看"的东西，混在笔记里找不到。个人手上 5–20 台设备，没有一个只干这件事的工具。

**2. 与最近三个竞品差在哪？**

| 能力 | Sortly | SmartLabels | 备忘录 | SerialShelf |
|---|---|---|---|---|
| 序列号从照片识别 | ✗ | ✗ | ✗ | ✓ 本机 Vision |
| 保修到期倒计时 | ✗ | ✗ | ✗ | ✓ |
| 到期前通知 | ✗ | ✗ | ✗ | ✓ 本地通知 |
| 需要账号 | ✓ | ✓ | ✗ | ✗ |
| 数据出设备 | ✓ | ✓ | 可能 | ✗ |
| 团队/库存模型 | ✓ | ✓ | ✗ | ✗（刻意不做） |

**3. 哪一项是独有的？**

序列号 OCR + 保修倒计时是组合出来的独立价值：**拍照 → 自动填序列号 → 记购买日期 → 到期前 30 天提醒**。现有产品要么有 OCR 没有保修（扫描类），要么有保修没有 OCR（记账类），没有一个把这两步接成一条线。

**4. 凭什么值得单独一个下载？**

因为这件事一年只用两次，但两次都很急——报修和二手转卖。这时候你在三个地方翻照片、翻邮箱、翻聊天记录。

## 商店文案

- **标题**（30 字符内）：SerialShelf — 序列号与保修
- **副标题**（30 字符内）：拍照存序列号，到期前提醒你
- **关键词**（100 字符内）：序列号,保修,SN,设备管理,序列号扫描,保修期,电子产品,二手,转卖,发票
- **描述首段**：
  说明书扔掉之后，序列号就找不到了。SerialShelf 让你对着标签拍一张照，自动认出序列号，记下购买日期，在保修到期前 30 天提醒你一次。数据只存在这台 iPhone 上，不联网、不要账号。
- **截图叙事**（5 张）：
  1. 拍到就存 —— 照片标签上高亮识别出的序列号
  2. 一眼看到哪台快过期 —— 列表里橙色"还剩 12 天"
  3. 报修时直接复制 —— 详情页的"复制序列号"
  4. 二手转卖一次说清 —— 完整信息页
  5. 不联网 —— "所有数据都在本机"的说明页

## 元数据自查

- [x] 标题、副标题与主要竞品不重复（Sortly / SmartLabels 是团队库存定位）
- [x] 描述没有套模板句
- [x] 截图叙事按"用户时刻"设计，不是功能列表
- [ ] 年龄分级、隐私标签（提交时填：不收集数据）
- [x] 审核备注可写明：OCR 与存储全部在本机，无网络请求

## 审核备注（写给 Reviewer）

> SerialShelf has no account, no network requests, and no third-party SDKs.
> Serial numbers are recognised on-device with Vision and stored with SwiftData.
> The only permission used is local notifications, requested after the user saves
> their first item, to remind them 30 days before a warranty expires.
