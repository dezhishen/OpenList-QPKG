# OpenList QPKG 自动构建

- 自动从 OpenList 官方 release 拉取二进制包
- 自动下载 OpenList-Resource 多分辨率 logo（优选 512 > 256 > 128）
- 自动多架构/标准/精简 QPKG 打包
- 每次构建会创建（或刷新） release/版本 分支与 Tag，所有 QPKG 配置与产物归档到分支，并上传到 Tag 对应 Release

Actions 手动可选参数：  
- `version`：版本号或 latest
- `edition`：normal/lite，可全打
- `arch`：架构，可全打