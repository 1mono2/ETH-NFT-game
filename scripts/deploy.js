const main = async () => {
  [owner, randomPerson] = await hre.ethers.getSigners();
  // MyEpicGame is compiled and deployed to the blockchain
  // これにより、`MyEpicGame` コントラクトがコンパイルされます。
  // コントラクトがコンパイルされたら、コントラクトを扱うために必要なファイルが
  // `artifacts` ディレクトリの直下に生成されます。
  const gameContractFactory = await hre.ethers.getContractFactory('MyEpicGame');
  // Create a new blockchain
  const gameContract = await gameContractFactory.deploy(
    ["ZORO", "NAMI", "USSOP"],
    [
      "QmPNEmaiWSaQhWYkjKBWctX5jwZ4t9WEPgssDNFwUT1RBx", // キャラクターの画像
      "QmNSa7MR5hcbJS1sHzx5AJ3HhHubChMYJhGGve7kJupii3",
      "QmQ59urX6G91McKCha59vL7j9JsACCx9ofZKWJ5CT5cEYd",
    ],
    [100, 200, 300],
    [100, 50, 25],
    "CROCODILE", // Bossの名前
    "https://i.imgur.com/BehawOh.png", // Bossの画像
    10000, // Bossのhp
    50 // Bossの攻撃力
  );
  // deploy the contract to local blockchain
  const nftGame = await gameContract.deployed();

  console.log("Contract deployed to:", nftGame.address);
  console.log("Contract deployed by:", owner.address);

  // /* ---- mintCharacterNFT関数を呼び出す ---- */
  // // 再代入可能な変数 txn を宣言
  // let txn;
  // // 3体のNFTキャラクターの中から、1番目のキャラクターを Mint しています。
  // txn = await gameContract.mintCharacterNFT(0);
  // // Minting が仮想マイナーにより、承認されるのを待ちます。
  // await txn.wait();
  // console.log("Minted NFT #1");

  // txn = await gameContract.mintCharacterNFT(1);
  // await txn.wait();
  // console.log("Minted NFT #2");

  // txn = await gameContract.mintCharacterNFT(2);
  // await txn.wait();
  // console.log("Minted NFT #3");
  // console.log("Done minting NFTs!")

  // // NFTのURIの値を取得します。tokenURI は ERC721 から継承した関数です。
  // let returnedTokenUri = await gameContract.tokenURI(1);
  // console.log("#1 Token URI:", returnedTokenUri)

  // // NFTの所有者のアドレスを取得します。ownerOf は ERC721 から継承した関数です。
  // let nftOwner = await gameContract.ownerOf(1);
  // console.log("#1 NFT Owner:", nftOwner);

  // console.log("Battle with the boss!");
  // txn = await gameContract.attackBoss();
  // await txn.wait();
  // console.log("First attack.");
  // txn = await gameContract.attackBoss();
  // await txn.wait();
  // console.log("Second attack.");

  console.log("Done!");
}

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
}
runMain();