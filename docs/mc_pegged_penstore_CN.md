### Openstore
Openstore 是 Opensea 使用的共享资产合约，遵循 ERC1155 标准
部署地址 https://polygonscan.com/address/0x2953399124F0cBB46d2CbACD8A89cF0599974963

### Openstore tokenId 格式
`0xeddf4a474bea02ac6184b445953bbe0d98effbbf000000000000010000000001`

```
eddf4a474bea02ac6184b445953bbe0d98effbbf    // 40 hex, token creator
00000000000001                              // 14 hex, token index
0000000001                                  // 10 hex, max supply
```

Token 类型用 creator+index 表示
max supply > 1 表示一种 FT 资产
max supply = 1 表示一个 NFT

### Openstore bridge on anycall
源链合约
1. Openstore - Opensea 官方合约
2. OpenstoreGateway - ERC1155 gateway, swapout = 锁定，swapin = 释放

目标链合约
1. MCPeggedOpenstore - Opensea 映射合约
2. ERC721Factory - ERC721 工厂合约
3. MCPeggedOpenstoreGateway - ERC1155 gateway, swapout = burn, swapin = mint, 有1155<=>721转换功能

### 1155 <=> 721 转换
ERC721 合约由 creator 账户通过 factory 创建, 一个 creator 只能创建一个 ERC721 合约

ERC721 合约创建后, MCPeggedOpenstore ERC1155 NFT 可以和 ERC721 NFT 互相转换

#### 1155 => 721 规则
1. max supply > 1 不是 NFT, 不允许转换
2. max supply = 1 可以转换, creator 和对应 ERC721 NFT collection 一一对应
3. 721 tokenId = 1155 token index

#### 721 => 1155 规则
1155 tokenId = <721 合约的 creator> + <721 tokenId> + <0000000001>