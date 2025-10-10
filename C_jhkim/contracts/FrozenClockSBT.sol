// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * Minimal Soulbound interface (EIP-5192)
 * All minted tokens are locked and non-transferable.
 */
interface IERC5192 {
    event Locked(uint256 tokenId);
    event Unlocked(uint256 tokenId);
    function locked(uint256 tokenId) external view returns (bool);
}

/**
 * FrozenClockSBT
 * - Only contract owner(발행 주체) 가 mint/burn 가능
 * - 전송/위임/승인 전부 불가 (SBT)
 * - tokenURI 가 온체인 SVG를 JSON(Base64)로 반환
 * - 입력값: recipient, externalId(생성ID), holderName, dateStr
 */
contract FrozenClockSBT is ERC721, Ownable, IERC5192 {
    using Strings for uint256;

    struct SoulData {
        string externalId;   // 생성ID (표기용)
        string holderName;   // 표시 이름
        string dateStr;      // 표시 날짜 (예: "2025.09.25")
        bool exists;
    }

    // 간단히 1부터 증가하는 토큰ID
    uint256 private _nextTokenId = 1;
    mapping(uint256 => SoulData) private _souls;

    constructor() ERC721("FrozenClock SBT", "FCSBT") Ownable(msg.sender) {}

    /// @notice 발행 (관리자만)
    function mint(
        address to,
        string memory externalId,
        string memory holderName,
        string memory dateStr
    ) external onlyOwner returns (uint256 tokenId) {
        tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _souls[tokenId] = SoulData({
            externalId: externalId,
            holderName: holderName,
            dateStr: dateStr,
            exists: true
        });
        emit Locked(tokenId);
    }

    /// @notice SBT: 항상 잠김
    function locked(uint256 tokenId) external view override returns (bool) {
        require(_exists(tokenId), "SBT: nonexistent");
        return true;
    }

    /// @notice 발행자가 회수(소각) 가능 (선택 사항)
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
        delete _souls[tokenId];
    }

    // ---- 전송/승인 모두 차단 (SBT) ----
    function approve(address, uint256) public pure override { revert("SBT: non-transferable"); }
    function setApprovalForAll(address, bool) public pure override { revert("SBT: non-transferable"); }
    function transferFrom(address, address, uint256) public pure override { revert("SBT: non-transferable"); }
    function safeTransferFrom(address, address, uint256) public pure override { revert("SBT: non-transferable"); }
    function safeTransferFrom(address, address, uint256, bytes memory) public pure override { revert("SBT: non-transferable"); }

    // ---- 메타데이터(JSON) + 온체인 SVG ----
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "SBT: nonexistent");
        SoulData memory d = _souls[tokenId];

        string memory svg = generateSVG(d.holderName, d.externalId, d.dateStr, tokenId);
        string memory img = Base64.encode(bytes(svg));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"', d.holderName, ' - ', d.externalId,
                        '","description":"Soulbound token with a frozen clock design. Non-transferable.",',
                        '"image":"data:image/svg+xml;base64,', img, '",',
                        '"attributes":[',
                            '{"trait_type":"External ID","value":"', d.externalId, '"},',
                            '{"trait_type":"Holder","value":"', d.holderName, '"},',
                            '{"trait_type":"Date","value":"', d.dateStr, '"},',
                            '{"trait_type":"TokenId","value":"', tokenId.toString(), '"}',
                        ']}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /// @dev 온체인 SVG 생성 (상단: 이름/ID, 중앙: 얼어있는 시계, 하단: 날짜)
    function generateSVG(
        string memory holderName,
        string memory externalId,
        string memory dateStr,
        uint256 tokenId
    ) internal pure returns (string memory) {
        // tokenId를 시드로 약간의 노이즈 패턴을 달리함
        string memory seed = Strings.toString(tokenId);

        string memory header = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">',
                "<defs>",
                '<radialGradient id="bg" cx="50%" cy="50%" r="75%">',
                    '<stop offset="0%" stop-color="#103C9E"/>',
                    '<stop offset="100%" stop-color="#2B7BFF"/>',
                "</radialGradient>",
                '<linearGradient id="rim" x1="0" y1="0" x2="0" y2="1">',
                    '<stop offset="0%" stop-color="#E5F3FF"/>',
                    '<stop offset="100%" stop-color="#83BBFF"/>',
                "</linearGradient>",
                '<filter id="frost">',
                    '<feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="', seed, '"/>',
                    '<feColorMatrix type="saturate" values="0.15"/>',
                    '<feBlend mode="screen"/>',
                    '<feGaussianBlur stdDeviation="1.2"/>',
                "</filter>",
                "</defs>",
                '<rect width="1024" height="1024" fill="url(#bg)"/>',
                '<rect x="42" y="42" width="940" height="940" fill="none" stroke="rgba(255,255,255,0.35)" stroke-width="4"/>',
                '<text x="512" y="120" text-anchor="middle" font-family="Pretendard,system-ui,sans-serif" font-size="44" fill="#FFFFFF">',
                    holderName, " · ID: ", externalId,
                "</text>"
            )
        );

        string memory clock = string(
            abi.encodePacked(
                '<g transform="translate(512,520)">',
                    // 외곽 링
                    '<circle r="270" fill="url(#rim)" opacity="0.15"/>',
                    '<circle r="250" fill="#FFFFFF" opacity="0.06"/>',
                    '<circle r="248" fill="none" stroke="#D9ECFF" stroke-width="4"/>',

                    // 눈금 (12개)
                    '<g stroke="#D9ECFF" stroke-width="3" opacity="0.9">',
                        '<line x1="0" y1="-230" x2="0" y2="-200"/>',
                        '<line x1="0" y1="-230" x2="0" y2="-200" transform="rotate(30)"/>',
                        '<line x1="0" y1="-230" x2="0" y2="-200" transform="rotate(60)"/>',
                        '<line x1="0" y1="-230" x2="0" y2="-200" transform="rotate(90)"/>',
                        '<line x1="0" y1="-230" x2="0" y2="-200" transform="rotate(120)"/>',
                        '<line x1="0" y1="-230" x2="0" y2="-200" transform="rotate(150)"/>',
                        '<line x1="0" y1="-230" x2="0" y2="-200" transform="rotate(180)"/>',
                        '<line x1="0" y1="-230" x2="0" y2="-200" transform="rotate(210)"/>',
                        '<line x1="0" y1="-230" x2="0" y2="-200" transform="rotate(240)"/>',
                        '<line x1="0" y1="-230" x2="0" y2="-200" transform="rotate(270)"/>',
                        '<line x1="0" y1="-230" x2="0" y2="-200" transform="rotate(300)"/>',
                        '<line x1="0" y1="-230" x2="0" y2="-200" transform="rotate(330)"/>',
                    '</g>',

                    // 시곗바늘 (10:10 느낌)
                    '<line x1="0" y1="0" x2="0" y2="-130" stroke="#FFFFFF" stroke-width="6" transform="rotate(-60)"/>',
                    '<line x1="0" y1="0" x2="0" y2="-190" stroke="#FFFFFF" stroke-width="3" transform="rotate(20)"/>',
                    '<circle r="7" fill="#FFFFFF"/>',

                    // 얼음(서리) 느낌 오버레이
                    '<g filter="url(#frost)" opacity="0.35">',
                        '<path d="M-230,-50 C-180,-120,-100,-170,-20,-180 C120,-190,210,-70,190,40 C170,140,50,220,-80,200 C-170,190,-230,70,-230,-50 Z" fill="#EAFFFF"/>',
                    '</g>',

                    // 간단한 눈송이 2개
                    '<g stroke="#E8F6FF" stroke-width="2" opacity="0.7">',
                        '<g transform="translate(-160,-120) rotate(15)">',
                            '<line x1="-12" y1="0" x2="12" y2="0"/>',
                            '<line x1="0" y1="-12" x2="0" y2="12"/>',
                            '<line x1="-8" y1="-8" x2="8" y2="8"/>',
                            '<line x1="-8" y1="8" x2="8" y2="-8"/>',
                        '</g>',
                        '<g transform="translate(160,120) rotate(-10)">',
                            '<line x1="-12" y1="0" x2="12" y2="0"/>',
                            '<line x1="0" y1="-12" x2="0" y2="12"/>',
                            '<line x1="-8" y1="-8" x2="8" y2="8"/>',
                            '<line x1="-8" y1="8" x2="8" y2="-8"/>',
                        '</g>',
                    '</g>',
                '</g>'
            )
        );

        string memory footer = string(
            abi.encodePacked(
                '<text x="512" y="920" text-anchor="middle" font-family="Pretendard,system-ui,sans-serif" font-size="36" fill="#E3F2FF">',
                    dateStr,
                "</text>",
                "</svg>"
            )
        );

        return string(abi.encodePacked(header, clock, footer));
    }

    /// 편의 조회
    function soul(uint256 tokenId)
        external
        view
        returns (string memory externalId, string memory holderName, string memory dateStr, address owner)
    {
        require(_exists(tokenId), "SBT: nonexistent");
        SoulData memory d = _souls[tokenId];
        return (d.externalId, d.holderName, d.dateStr, ownerOf(tokenId));
    }
}
