# 第三方组件声明 / Third-Party Notices

本仓库的 `EFI/oc/Kexts/` 中包含多个第三方内核扩展。它们由各自作者所有，按其各自的许可证授权。本仓库仅原样收录这些组件的已发布二进制文件，**未作修改、未作逆向、未作为衍生作品发布**。各组件的完整权利归其原作者所有。

以下列出本 EFI 中启用的主要组件及其上游项目，供使用者查阅各自的许可证全文。若你打算再次分发或修改任一组件，请先阅读对应的上游许可证。

| 组件 | 上游项目 |
| --- | --- |
| Lilu | acidanthera/Lilu |
| AppleALC | acidanthera/AppleALC |
| RestrictEvents | acidanthera/RestrictEvents |
| BlueToolFixup | acidanthera/BlueToolFixup |
| AirportItlwm / itlwm | laobamac / OpenIntelWireless |
| SimpleHDA | laobamac/SimpleHDA |
| VoodooI2C / VoodooI2CHID / VoodooI2CELAN | alexandred/VoodooI2C |
| VoodooPS2Controller | alexandred/VoodooPS2Controller |
| VirtualSMC / SMC* 系列 | acidanthera/VirtualSMC |
| AMFIPass | dhinakg/AMFIPass |
| NVMeFix | acidanthera/NVMeFix |
| BrightnessKeys | acidanthera/BrightnessKeys |
| ECEnabler | 1Revenger1/ECEnabler |
| **NootedRed** | **ChefKissInc/NootedRed** |

---

## NootedRed

本仓库收录 `EFI/oc/Kexts/NootedRed.kext`，为上游 GitHub Releases 发布的正式版二进制的**逐字完整副本**（未修改内容或行为），作为本 EFI 这一集合作品中的一个**独立、可分离、未改变**的组件。

- **上游项目**：https://github.com/ChefKissInc/NootedRed
- **版权所有**：Copyright (C) 2022-2026 ChefKiss
- **适用许可证**：ChefKiss Open Knowledge License version 1（或其后由 ChefKiss 发布的更新版本）
- **许可证全文（官方）**：https://git.chefkiss.dev/ChefKiss/OpenKnowledge/raw/branch/master/LICENSE-v1.md

按该许可证第 1b 条，本副本同样按 ChefKiss Open Knowledge License version 1 授权。按第 9 条，原样保留上游要求附随的版权与许可通知如下：

```
Copyright (C) 2022-2026  ChefKiss

Licensed under the ChefKiss Open Knowledge License version 1.

This work is licensed to you under the terms of the ChefKiss Open Knowledge
License, either version 1 of the License, or (at your option) any later
version published by ChefKiss.

This work may not be used to train or develop artificial intelligence,
and may not be used with artificial intelligence in any other way. See
the ChefKiss Open Knowledge License for details.

This work is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
ChefKiss Open Knowledge License for more details.

You should have received a copy of the ChefKiss Open Knowledge License
along with this work.  If not, see https://git.chefkiss.dev/ChefKiss/OpenKnowledge/raw/branch/master/LICENSE-v1.md.
```

**请特别注意**：该许可证第 3 条对 AI（机器学习 / 大模型 / 生成式系统及其工具、服务、代理）的使用有严格限制，包括不得以任何方式让 AI 读取、总结、分析、翻译或复现该作品，以及不得将其纳入数据集、知识库或作为输入、上下文、检索材料提供给 AI。该条款适用于每个副本及每位接收者，无论商业或非商业用途。你在获取或使用此组件前，应自行阅读并判断是否接受上述条款；本页面仅为转述与提示，不构成法律意见。
