"""解析 Make Me A Hanzi 的 IDS 拆解，并生成儿童向讲解文案。"""

from __future__ import annotations

import json
import urllib.request
from pathlib import Path

from evolution_hints import make_evolution_hint
from fun_decompose_hints import (
    FUN_FALLBACK_THREE,
    FUN_FALLBACK_TWO,
    LEVEL1_FUN_HINTS,
    PICTOGRAPH_FALLBACK,
    RADICAL_STORY_RULES,
    all_fun_hints,
)

IDS_BINARY = "⿰⿱⿴⿵⿶⿷⿸⿹⿺⿻"
IDS_TERNARY = "⿲⿳"
DICT_CACHE = Path(__file__).resolve().parent / "makemeahanzi_dictionary.txt"
DICT_URL = "https://raw.githubusercontent.com/skishore/makemeahanzi/master/dictionary.txt"

# 常见偏旁/部件 → 儿童能懂的名字
COMPONENT_KID_NAMES: dict[str, str] = {
    "日": "太阳",
    "月": "月亮",
    "女": "女性",
    "亻": "人",
    "人": "人",
    "子": "孩子",
    "马": "马",
    "宀": "房子",
    "豕": "猪",
    "木": "树木",
    "水": "水",
    "氵": "三点水",
    "火": "火",
    "土": "土地",
    "金": "金属",
    "石": "石头",
    "山": "山",
    "口": "嘴巴",
    "心": "心",
    "忄": "竖心旁",
    "手": "手",
    "扌": "提手旁",
    "足": "脚",
    "⻊": "足字旁",
    "目": "眼睛",
    "耳": "耳朵",
    "田": "田地",
    "禾": "禾苗",
    "米": "米",
    "虫": "虫子",
    "鱼": "鱼",
    "鸟": "鸟",
    "车": "车",
    "门": "门",
    "户": "户",
    "衣": "衣服",
    "衤": "衣字旁",
    "食": "食物",
    "饣": "食字旁",
    "言": "说话",
    "讠": "言字旁",
    "走": "走路",
    "辶": "走之底",
    "雨": "雨",
    "风": "风",
    "父": "爸爸",
    "母": "妈妈",
    "大": "大",
    "小": "小",
    "也": "也",
    "巴": "巴",
    "白": "白",
    "青": "青",
    "红": "红",
    "绿": "绿",
    "黄": "黄",
    "黑": "黑",
    "犬": "狗",
    "犭": "反犬旁",
    "牛": "牛",
    "羊": "羊",
    "鸟": "鸟",
    "羽": "羽毛",
    "艹": "草字头",
    "竹": "竹子",
    "⺮": "竹字头",
    "王": "玉",
    "玉": "玉",
    "王": "王",
    "贝": "贝壳",
    "见": "看见",
    "页": "页",
    "刀": "刀",
    "刂": "立刀旁",
    "力": "力气",
    "又": "又",
    "寸": "寸",
    "戈": "戈",
    "斤": "斤",
    "歹": "歹",
    "止": "止",
    "攵": "反文旁",
    "文": "文",
    "立": "立",
    "穴": "洞穴",
    "广": "广",
    "厂": "厂",
    "尸": "尸",
    "匚": "框",
    "凵": "凵",
    "乙": "乙",
    "十": "十",
    "一": "一",
    "二": "二",
    "三": "三",
    "四": "四",
    "五": "五",
    "六": "六",
    "七": "七",
    "八": "八",
    "九": "九",
    "儿": "儿",
    "匕": "匕",
    "卜": "卜",
    "瓜": "瓜",
    "果": "果",
    "豆": "豆",
    "菜": "菜",
    "饭": "饭",
    "门": "门",
    "窗": "窗",
    "床": "床",
    "桌": "桌",
    "椅": "椅",
    "灯": "灯",
    "书": "书",
    "笔": "笔",
    "包": "包",
    "衣": "衣",
    "明": "明亮",
    "昨": "昨天",
    "早": "早",
    "晚": "晚",
    "春": "春天",
    "夏": "夏天",
    "秋": "秋天",
    "东": "东方",
    "南": "南方",
    "西": "西方",
    "北": "北方",
    "上": "上面",
    "下": "下面",
    "左": "左",
    "右": "右",
    "里": "里面",
    "前": "前面",
    "后": "后面",
    "高": "高",
    "低": "低",
    "长": "长",
    "短": "短",
    "好": "好",
    "坏": "坏",
    "新": "新",
    "旧": "旧",
    "快": "快",
    "慢": "慢",
    "开": "开",
    "关": "关",
    "想": "想",
    "说": "说",
    "听": "听",
    "叫": "叫",
    "走": "走",
    "坐": "坐",
    "站": "站",
    "睡": "睡",
    "起": "起",
    "玩": "玩",
    "学": "学",
    "写": "写",
    "读": "读",
    "拿": "拿",
    "放": "放",
    "给": "给",
    "要": "要",
    "能": "能",
    "不": "不",
    "没": "没",
    "有": "有",
    "是": "是",
    "个": "个",
    "只": "只",
}

FUN_HINTS = all_fun_hints()

# 基础字 / 象形字：手动补充（Make Me A Hanzi 无可靠拆解时）
def _manual_entry(ch: str, parts: list[str]) -> tuple[list[str], str]:
    hint = LEVEL1_FUN_HINTS.get(ch) or FUN_HINTS.get(ch) or PICTOGRAPH_FALLBACK.format(char=ch)
    return parts, hint


MANUAL_DECOMPOSITIONS: dict[str, tuple[list[str], str]] = {
    ch: _manual_entry(ch, parts)
    for ch, parts in {
        "多": ["夕", "夕"],
        "手": [],
        "心": [],
        "牛": [],
        "鸟": [],
        "一": [],
        "二": [],
        "三": [],
        "大": [],
        "小": [],
        "口": [],
        "日": [],
        "月": [],
        "山": [],
        "水": [],
        "火": [],
        "木": [],
        "土": [],
        "人": [],
        "马": [],
        "羊": [],
        "鱼": [],
        "虫": [],
        "我": ["扌", "戈"],
        "头": ["大", "页"],
        "足": [],
        "耳": [],
        "瓜": [],
        "衣": [],
        "书": [],
        "年": ["禾", "千"],
        "春": ["三", "日"],
        "北": ["匕", "匕"],
        "上": [],
        "左": ["工", "口"],
        "右": ["口", "口"],
        "长": [],
        "黑": ["里", "灬"],
        "白": [],
    }.items()
}


def _is_ids_op(ch: str) -> bool:
    return ch in IDS_BINARY or ch in IDS_TERNARY


def _child_count(op: str) -> int:
    return 3 if op in IDS_TERNARY else 2


def _extract_component(text: str) -> tuple[str, str]:
    if not text:
        return "", ""
    if _is_ids_op(text[0]):
        op = text[0]
        count = _child_count(op)
        pos = 1
        for _ in range(count):
            _, pos = _extract_component_at(text, pos)
        return text[:pos], text[pos:]
    return text[0], text[1:]


def _extract_component_at(text: str, start: int) -> tuple[str, int]:
    if start >= len(text):
        return "", start
    if _is_ids_op(text[start]):
        op = text[start]
        count = _child_count(op)
        pos = start + 1
        for _ in range(count):
            _, pos = _extract_component_at(text, pos)
        return text[start:pos], pos
    return text[start], start + 1


def _display_component(component: str) -> str:
    """取部件里最显眼的一个汉字，便于儿童辨认。"""
    if not component:
        return ""
    if not _is_ids_op(component[0]):
        return component
    op = component[0]
    count = _child_count(op)
    pos = 1
    leaves: list[str] = []
    for _ in range(count):
        child, pos = _extract_component_at(component, pos)
        leaves.append(_display_component(child))
    return leaves[0] if leaves else component


def _is_displayable_part(part: str) -> bool:
    if not part or part in {"？", "?"}:
        return False
    if part in COMPONENT_KID_NAMES:
        return True
    return len(part) == 1 and "\u4e00" <= part <= "\u9fff"


def immediate_components(decomposition: str | None) -> list[str]:
    if not decomposition or decomposition in {"？", "?"}:
        return []
    if not _is_ids_op(decomposition[0]):
        return []
    op = decomposition[0]
    count = _child_count(op)
    pos = 1
    parts: list[str] = []
    for _ in range(count):
        child, pos = _extract_component_at(decomposition, pos)
        shown = _display_component(child)
        if shown and _is_displayable_part(shown) and shown not in parts:
            parts.append(shown)
    return parts


def _kid_name(part: str) -> str:
    return COMPONENT_KID_NAMES.get(part, f"「{part}」")


def make_decompose_hint(character: str, components: list[str]) -> str | None:
    if character in FUN_HINTS:
        return FUN_HINTS[character]

    if len(components) == 2:
        left, right = components
        ln, rn = _kid_name(left), _kid_name(right)
        for radicals, template in RADICAL_STORY_RULES:
            if left in radicals:
                return template.format(char=character, rn=rn)
        return FUN_FALLBACK_TWO.format(char=character, ln=ln, rn=rn)

    if len(components) == 3:
        a, b, c = components
        an, bn, cn = _kid_name(a), _kid_name(b), _kid_name(c)
        for radicals, template in RADICAL_STORY_RULES:
            if a in radicals:
                return template.format(char=character, rn=f"{bn}、{cn}")
        return FUN_FALLBACK_THREE.format(char=character, an=an, bn=bn, cn=cn)

    return None


def ensure_dictionary() -> None:
    if DICT_CACHE.exists() and DICT_CACHE.stat().st_size > 1_000_000:
        return
    print(f"下载字库拆解数据 → {DICT_CACHE.name}")
    with urllib.request.urlopen(DICT_URL, timeout=120) as resp:
        DICT_CACHE.write_bytes(resp.read())


def load_decomposition_map() -> dict[str, dict[str, object]]:
    ensure_dictionary()
    result: dict[str, dict[str, object]] = {}
    with DICT_CACHE.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            data = json.loads(line)
            ch = data.get("character")
            if not ch or len(ch) != 1:
                continue
            decomp = data.get("decomposition")
            etymology = data.get("etymology")
            parts = immediate_components(decomp)
            hint = make_decompose_hint(ch, parts)
            evo_type, evo_hint = make_evolution_hint(ch, etymology, parts or None)

            entry: dict[str, object] = {}
            if parts and hint:
                entry["components"] = parts
                entry["decomposeHint"] = hint
            elif hint:
                entry["decomposeHint"] = hint
                if parts:
                    entry["components"] = parts
            if evo_hint:
                if evo_type:
                    entry["evolutionType"] = evo_type
                entry["evolutionHint"] = evo_hint
            if entry:
                result[ch] = entry
    for ch, (parts, hint) in MANUAL_DECOMPOSITIONS.items():
        evo_type, evo_hint = make_evolution_hint(ch, None, parts or None)
        manual: dict[str, object] = {"decomposeHint": hint}
        if parts:
            manual["components"] = parts
        if evo_hint:
            if evo_type:
                manual["evolutionType"] = evo_type
            manual["evolutionHint"] = evo_hint
        result[ch] = manual
    return result


def lookup_decomposition(
    character: str, cache: dict[str, dict[str, object]]
) -> tuple[list[str] | None, str | None, str | None, str | None]:
    """返回 (components, decomposeHint, evolutionType, evolutionHint)。"""
    entry = cache.get(character)
    if not entry:
        return None, None, None, None

    components = entry.get("components")
    hint = entry.get("decomposeHint")
    evo_type = entry.get("evolutionType")
    evo_hint = entry.get("evolutionHint")

    comp_out: list[str] | None = None
    if isinstance(components, list) and components:
        comp_out = components

    hint_out = hint if isinstance(hint, str) and hint else None
    evo_type_out = evo_type if isinstance(evo_type, str) and evo_type else None
    evo_hint_out = evo_hint if isinstance(evo_hint, str) and evo_hint else None

    return comp_out, hint_out, evo_type_out, evo_hint_out
