// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// NFT発行のコントラクト ERC721.sol をインポートします。
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";

//OpenZeppelinが提供するヘルパー機能をインポートします。
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/utils/Strings.sol";

import "../node_modules/hardhat/console.sol";

import "./libraries/Base64.sol";

contract MyEpicGame is ERC721 {
    // キャラクターのデータを格納する CharacterAttributes 型の 構造体（`struct`）を作成しています。
    struct CharacterAttributes {
        uint256 characterIndex;
        string name;
        string imageURI;
        uint256 maxHp;
        uint256 hp;
        uint256 attackDamage;
    }

    struct BigBoss {
        string name;
        string imageURI;
        uint256 maxHp;
        uint256 hp;
        uint256 attackDamage;
    }
    BigBoss public bigBoss;

    //OpenZeppelin が提供する tokenIds を簡単に追跡するライブラリを呼び出しています。
    using Counters for Counters.Counter;
    // tokenIdはNFTの一意な識別子で、0, 1, 2, .. N のように付与されます。
    Counters.Counter private _tokenIds;

    // キャラクターのデフォルトデータを保持するための配列 defaultCharacters を作成します。それぞれの配列は、CharacterAttributes 型です。
    CharacterAttributes[] defaultCharacters;

    // NFTの tokenId と CharacterAttributes を紐づける mapping を作成します。
    mapping(uint256 => CharacterAttributes) public nftHolderAttributes;

    // ユーザーのアドレスと NFT の tokenId を紐づける mapping を作成しています。
    mapping(address => uint256) public nftHolders;

    // ユーザーが NFT を Mint したこと示すイベント
    event CharacterMinted(
        address sender,
        uint256 tokenId,
        uint256 characterIndex
    );

    // ボスへの攻撃が完了したことを示すイベント
    event AttackCompleted(uint newBossHp, uint newPlayerHp);

    constructor(
        // プレイヤーが新しく NFT キャラクターを Mint する際に、キャラクターを初期化するために渡されるデータを設定しています。これらの値は フロントエンド（js ファイル）から渡されます。
        string[] memory characterNames,
        string[] memory characterImageURIs,
        uint256[] memory characterMaxHp,
        uint256[] memory characterAttackDamage,
        // boss argument
        string memory bossNames,
        string memory bossImageURIs,
        uint bossMaxHp,
        uint bossAttackDamage
    )
        // 作成するNFTの名前とそのシンボルをERC721規格に渡しています。
        ERC721("OnePiece", "ONEPIESE")
    {
        // ボスを初期化します。ボスの情報をグローバル状態変数 "bigBoss"に保存します。
        bigBoss = BigBoss({
            name: bossNames,
            imageURI: bossImageURIs,
            maxHp: bossMaxHp,
            hp: bossMaxHp,
            attackDamage: bossAttackDamage
        });
        console.log(
            "Done initializing boss %s with HP %s, and damage %s",
            bigBoss.name,
            bigBoss.hp,
            bigBoss.attackDamage
        );

        // ゲームで扱う全てのキャラクターをループ処理で呼び出し、それぞれのキャラクターに付与されるデフォルト値をコントラクトに保存します。
        // 後でNFTを作成する際に使用します。
        for (uint256 i = 0; i < characterNames.length; i += 1) {
            defaultCharacters.push(
                CharacterAttributes({
                    characterIndex: i,
                    name: characterNames[i],
                    imageURI: characterImageURIs[i],
                    maxHp: characterMaxHp[i],
                    hp: characterMaxHp[i],
                    attackDamage: characterAttackDamage[i]
                })
            );
            CharacterAttributes memory character = defaultCharacters[i];
            // hardhat の console.log() では、任意の順番で最大4つのパラメータを指定できます。
            // 使用できるパラメータの種類: uint, string, bool, address
            console.log(
                "Done initializing character %s with HP %s, and damage %s",
                character.name,
                character.hp,
                character.attackDamage
            );
        }
        // 次の NFT が Mint されるときのカウンターをインクリメントします。
        _tokenIds.increment();
    }

    // ユーザーは mintCharacterNFT 関数を呼び出して、NFT を Mint ことができます。
    // _characterIndex は フロントエンドから送信されます。
    function mintCharacterNFT(uint _characterIndex) external {
        // 現在の tokenId を取得します（constructor内でインクリメントしているため、1から始まります）
        uint256 newItemId = _tokenIds.current();

        // msg.sender でフロントエンドからユーザーのアドレスを取得して、NFT をユーザーに Mint します。
        _safeMint(msg.sender, newItemId);

        // mapping で定義した tokenId を CharacterAttributesに紐付けます。
        nftHolderAttributes[newItemId] = CharacterAttributes({
            characterIndex: _characterIndex,
            name: defaultCharacters[_characterIndex].name,
            imageURI: defaultCharacters[_characterIndex].imageURI,
            maxHp: defaultCharacters[_characterIndex].maxHp,
            hp: defaultCharacters[_characterIndex].hp,
            attackDamage: defaultCharacters[_characterIndex].attackDamage
        });

        console.log(
            "Minted NFT w/ tokenId %s and characterIndex %s",
            newItemId,
            _characterIndex
        );

        nftHolders[msg.sender] = newItemId;

        // 次に使用する人のためにtokenIdをインクリメントします。
        _tokenIds.increment();

        // ユーザーが NFT を Mint したことをフロントエンドに伝えます。
        emit CharacterMinted(msg.sender, newItemId, _characterIndex);
    }

    function attackBoss() public {
        // 1. プレイヤーのNFTの状態を取得します。
        uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
        CharacterAttributes storage player = nftHolderAttributes[
            nftTokenIdOfPlayer
        ];
        console.log(
            "Player %s is attacking. Has %s HP and %s AD",
            player.name,
            player.hp,
            player.attackDamage
        );
        console.log(
            "Boss %s has %s HP and %s AD",
            bigBoss.name,
            bigBoss.hp,
            bigBoss.attackDamage
        );

        // 2. プレイヤーのHPが0以上であることを確認する。
        require(player.hp > 0, "Player must have HP to attack");
        // 3. ボスのHPが0以上であることを確認する。
        require(bigBoss.hp > 0, "Boss must have HP to be attacked");

        // 4. プレイヤーの攻撃力をボスのHPから減算する。
        if (bigBoss.hp > player.attackDamage) {
            bigBoss.hp = bigBoss.hp - player.attackDamage;
        } else {
            bigBoss.hp = 0;
        }

        // 5. ボスの攻撃力をプレイヤーのHPから減算する。
        if (player.hp > bigBoss.attackDamage) {
            player.hp = player.hp - bigBoss.attackDamage;
        } else {
            player.hp = 0;
        }

        // プレイヤーの攻撃をターミナルに出力する。
        console.log(
            "Player %s attacked Boss %s. Boss HP is now %s",
            player.name,
            bigBoss.name,
            bigBoss.hp
        );
        // ボスの攻撃をターミナルに出力する。
        console.log(
            "Boss %s attacked Player %s. Player HP is now %s",
            bigBoss.name,
            player.name,
            player.hp
        );

        // ボスへの攻撃が完了したことをフロントエンドに伝えます。
        emit AttackCompleted(bigBoss.hp, player.hp);
    }

    function checkIfUserHasNFT()
        public
        view
        returns (CharacterAttributes memory)
    {
        // ユーザーの tokenId を取得します。
        uint256 nftTokenId = nftHolders[msg.sender];

        // // ユーザーがすでにtokenIdを持っている場合、そのキャラクターの属性情報を返します。
        if (nftTokenId > 0) {
            return nftHolderAttributes[nftTokenId];
        }
        // それ以外の場合は、空文字を返します。
        return CharacterAttributes(0, "", "", 0, 0, 0);
    }

    function getAllDefaultCharacters()
        public
        view
        returns (CharacterAttributes[] memory)
    {
        return defaultCharacters;
    }

    function getBigBoss() public view returns (BigBoss memory) {
        return bigBoss;
    }

    // nftHolderAttributes を更新して、tokenURI を添付する関数を作成
    function tokenURI(
        uint256 _tokenID
    ) public view override returns (string memory) {
        CharacterAttributes memory character = nftHolderAttributes[_tokenID];
        // charAttributes のデータ編集して、JSON の構造に合わせた変数に格納しています。
        string memory strHP = Strings.toString(character.hp);
        string memory strMaxHP = Strings.toString(character.maxHp);
        string memory strAttackDamage = Strings.toString(
            character.attackDamage
        );

        string memory json = Base64.encode(
            // abi.encodePacked で文字列を結合します。
            // OpenSeaが採用するJSONデータをフォーマットしています。
            abi.encodePacked(
                '{"name": "',
                character.name,
                " -- NFT #: ",
                Strings.toString(_tokenID),
                '", "description": "This is an NFT that lets people play in the game Metaverse Slayer!", "image": "ipfs://',
                character.imageURI,
                '", "attributes": [ { "trait_type": "Health Points", "value": ',
                strHP,
                ', "max_value": ',
                strMaxHP,
                ' }, { "trait_type": "Attack Damage", "value": ',
                strAttackDamage,
                " } ]}"
            )
        );

        // 文字列 data:application/json;base64, と json の中身を結合して、tokenURI を作成しています。
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return output;
    }
}
