"""汉字演变/字源：儿童向讲解文案。"""

from __future__ import annotations

import re

# 字源类型 → 儿童能懂的名称
EVOLUTION_TYPE_LABELS: dict[str, str] = {
    "pictographic": "象形",
    "ideographic": "会意",
    "pictophonetic": "形声",
}

# Level 1 常用字：手工编写演变故事（与趣味拆解互补，侧重「古时候像什么」）
LEVEL1_EVOLUTION_HINTS: dict[str, str] = {
    "我": "古时候，一只手（扌）握着小小兵器（戈），表示自己——慢慢写成今天的「我」。",
    "你": "「亻」表示人，「尔」表读音——合在一起专门指对面的「你」。",
    "他": "人字旁（亻）加「也」，指着旁边的人说：是他！",
    "她": "女字旁表示女性，加「也」表音——用来称呼「她」。",
    "爸": "上面是「父」，下面是「巴」表音——叫爸爸！",
    "妈": "女字旁表示妈妈，「马」表音——小时候常喊「妈妈」写成「妈」。",
    "家": "屋字头（宀）像房顶，下面「豕」是猪——古人家里养猪，有吃有住就是「家」。",
    "来": "像带着麦穗走来——「来」了、来做客了！",
    "去": "像脚离开地面走开——从这儿到别处，就是「去」。",
    "看": "手（手）搭在眼睛（目）上远望——这就是「看」！",
    "出": "像小苗从坑里长出来——从里面到外面，就是「出」。",
    "吃": "嘴巴（口）加上表音的字——跟嘴有关，就是「吃」。",
    "喝": "嘴巴（口）加上表音——咕噜咕噜「喝」水！",
    "跑": "足字旁表示脚，「包」表音——小脚丫带着风「跑」！",
    "跳": "足字旁加「兆」——脚底下弹起来，就是「跳」！",
    "笑": "像人（夭）眉开眼笑，上面像弯弯的竹——开心就「笑」！",
    "哭": "口像张大的嘴，旁边像泪——伤心就「哭」啦。",
    "大": "像人张开手脚，占好大地方——就是「大」！",
    "小": "中间一竖，两边分开——东西变「小」啦。",
    "多": "两个「夕」叠在一起——越来越多，就是「多」！",
    "少": "在「小」上轻轻一撇——东西变「少」了。",
    "天": "「大」人头顶一横——比人还大的，就是「天」！",
    "地": "土字旁表示土地，「也」表音——我们踩的「地」！",
    "日": "圆圆的一格——像太阳公公，象形字「日」！",
    "月": "弯弯像眉毛——晚上天上的月亮「月」！",
    "水": "中间一竖，两边像水花——哗啦啦的「水」！",
    "火": "像火苗往上蹿——象形字「火」！",
    "木": "一竖是树干，两横两撇是树枝——一棵「木」！",
    "金": "像金属或铃铛的形状——亮晶晶的「金」！",
    "土": "像地上鼓起的一小堆——「土」！",
    "山": "三座山峰连在一起——高高的「山」！",
    "头": "「大」在上，「页」在下——身体最上面是「头」！",
    "手": "像张开的手指——象形字「手」！",
    "足": "像人的脚——走路用的「足」！",
    "心": "弯弯曲曲像小心脏——「心」里装着感觉。",
    "眼": "「目」像眼睛——用来看世界的「眼」！",
    "耳": "弯弯像耳朵——用来听的「耳」！",
    "口": "方方框框像张开的嘴——「口」！",
    "狗": "反犬旁表示动物，「句」表音——汪汪「狗」！",
    "猫": "反犬旁加「苗」——喵喵「猫」！",
    "马": "像一匹有鬃毛的马——象形字「马」！",
    "牛": "像牛角和牛身——「牛」！",
    "羊": "两点像羊角——咩咩「羊」！",
    "鸡": "又加鸟——喔喔叫的「鸡」！",
    "鱼": "中间像鱼鳞，下面像尾巴——游啊游的「鱼」！",
    "鸟": "有头有翅有尾巴——扑棱棱的「鸟」！",
    "虫": "像一条小虫子——爬啊爬的「虫」！",
    "花": "草字头加「化」——能开能香的就是「花」！",
    "草": "草字头加「早」——清晨沾露珠的小「草」！",
    "树": "木字旁加「对」——好多木头站在一起是「树」！",
    "叶": "像一片叶子挂在枝上——「叶」！",
    "米": "像一粒粒白「米」！",
    "瓜": "像藤上结的大「瓜」！",
    "豆": "像盛豆子的器皿——「豆」！",
    "菜": "草字头加「采」——采来能吃的「菜」！",
    "饭": "食字旁加「反」——用米做的香香「饭」！",
    "车": "像有轮子的「车」——象形字！",
    "门": "像两扇「门」——推开就能进出！",
    "窗": "穴字头加「囱」——墙上透光的小「窗」！",
    "床": "广字头加木——木头做的「床」！",
    "衣": "像一件挂着的「衣」服！",
    "笔": "竹字头加「毛」——竹管加毛，是写字的「笔」！",
    "纸": "纟旁加「氏」——用纤维做的「纸」！",
    "书": "像笔在写——把字记在一起就是「书」！",
    "包": "外面像包起来——把东西「包」住！",
    "桌": "「卓」加木——木头做的「桌」子！",
    "椅": "木加「奇」——有靠背可以坐的「椅」！",
    "灯": "火加「丁」——火亮起来就是「灯」！",
    "年": "禾加千——庄稼一年一熟，是「年」！",
    "明": "「日」和「月」都亮——合在一起是「明」！",
    "昨": "日字旁加「乍」——刚过去的那一天是「昨」天！",
    "早": "「日」加「十」——太阳刚升起来是「早」！",
    "晚": "「日」加「免」——太阳下山是「晚」上！",
    "春": "「日」照万物——阳光一照，春天「春」来了！",
    "夏": "像人顶着日头——热辣辣的是「夏」天！",
    "秋": "禾加火——庄稼熟了像火一样金，是「秋」天！",
    "东": "像太阳从树后升起——「东」边！",
    "南": "像入门方向——「南」边！",
    "西": "像太阳落下——「西」边！",
    "北": "两个人背对背——后来指「北」方！",
    "上": "一横在上面——往上就是「上」！",
    "下": "一横在下面——往下就是「下」！",
    "左": "工加口——左手边是「左」！",
    "右": "手加口——右手边是「右」！",
    "里": "田加土——有田有土的地方是「里」面！",
    "前": "像刀剪开——走在最「前」面！",
    "高": "上面像塔顶——站得「高」高的！",
    "低": "人加「氐」——身子往下弯是「低」！",
    "长": "像长发飘飘——形容「长」长的！",
    "短": "矢加豆——不够长就是「短」！",
    "红": "纟旁加「工」——像丝线一样「红」！",
    "黑": "里加四点——像烟熏火燎，是「黑」的！",
    "白": "像一盏亮灯——干干净净是「白」！",
    "好": "女加子——妈妈抱着孩子，就是好「好」！",
    "坏": "土加「不」——东西弄「坏」啦！",
    "新": "亲加斤——刚砍下的，是「新」的！",
    "旧": "竖加日——太阳旧旧的，是「旧」的！",
    "快": "竖心旁加「夬」——心里嗖嗖的，是「快」！",
    "慢": "竖心旁加「曼」——心里不着急，是「慢」！",
    "开": "像门闩打开——「开」门啦！",
    "关": "像门闩关上——「关」门啦！",
    "想": "「相」加「心」——心里冒出画面，就是「想」！",
    "说": "言字旁加「兑」——用嘴巴「说」话！",
    "听": "口加斤——侧耳「听」！",
    "叫": "口加「丩」——张开嘴「叫」！",
    "走": "像人迈开步子——「走」路去！",
    "坐": "两个人在土上——「坐」下来！",
    "站": "立加占——「站」直喽！",
    "睡": "目加垂——眼皮垂下来要「睡」觉！",
    "起": "走加己——从躺着到「起」来！",
    "玩": "王加元——拿着宝贝「玩」！",
    "学": "冖下子——孩子在屋里「学」！",
    "写": "冖下与——把字「写」下来！",
    "读": "言字旁加「卖」——把书「读」出来！",
    "拿": "合手——合起来用手「拿」！",
    "放": "方加攵——把东西「放」开！",
    "给": "纟加合——把东西「给」别人！",
    "要": "西加女——「要」这个！",
    "能": "像熊——有力气就「能」！",
    "不": "像花萼——表示「不」！",
    "没": "三点水加「殳」——「没」有了！",
    "有": "手加肉——「有」东西啦！",
    "是": "日加正——对呀，「是」这样！",
    "个": "人加竖——一个两个的「个」！",
    "只": "口加八——单单「只」有一个！",
    "一": "一横——数字「一」，也像一根线！",
    "二": "两横——数字「二」！",
    "三": "三横——数字「三」！",
    "四": "四方框——数字「四」！",
    "五": "像交叉线——数字「五」！",
    "六": "一点两撇——数字「六」！",
    "七": "一横弯钩——数字「七」！",
    "八": "像分开的路——数字「八」！",
    "九": "像弯弯的钩子——数字「九」！",
    "十": "一横一竖——数字「十」！",
}

# 英文词 → 中文（字源 hint 翻译）
_EN_WORD_MAP: dict[str, str] = {
    "sun": "太阳",
    "crescent moon": "弯弯的月亮",
    "moon": "月亮",
    "tree": "树",
    "flames": "火苗",
    "flame": "火",
    "fire": "火",
    "water": "水",
    "river": "河流",
    "mountain": "山",
    "person": "人",
    "man": "人",
    "woman": "女人",
    "hand": "手",
    "foot": "脚",
    "mouth": "嘴巴",
    "eye": "眼睛",
    "eyes": "眼睛",
    "heart": "心",
    "bird": "鸟",
    "fish": "鱼",
    "horse": "马",
    "dog": "狗",
    "house": "房子",
    "roof": "房顶",
    "father": "爸爸",
    "mother": "妈妈",
    "earth": "土地",
    "heaven": "天",
    "weapon": "兵器",
    "nail": "钉子",
    "table": "桌子",
    "pebble": "小石子",
    "lamp": "灯",
    "grass": "草",
    "ear": "耳朵",
    "tears": "眼泪",
    "tear": "眼泪",
}

# 常见英文句式替换
_EN_PATTERNS: list[tuple[str, str]] = [
    (r"Simplified form of\s*(\S+)", r"「\1」的简化写法"),
    (r"compare\s*(\S+)", r"跟「\1」很像"),
    (r"Compare\s*(\S+)", r"跟「\1」很像"),
    (r"variant of\s*(\S+)", r"「\1」的另一种写法"),
    (r"Represents\s+(.+)", r"表示\1"),
    (r"A\s+(.+?)\s+holding\s+(.+)", r"\1握着\2"),
    (r"(\S+)\s+provides the pronunciation", r"「\1」帮助读音"),
    (r"semantic[\":]?\s*[\"']?(\S+)[\"']?", r"表意思的「\1」"),
    (r"phonetic[\":]?\s*[\"']?(\S+)[\"']?", r"表读音的「\1」"),
]

_SEMANTIC_HINT_ZH: dict[str, str] = {
    "mouth": "嘴巴",
    "foot": "脚",
    "hand": "手",
    "water": "水",
    "fire": "火",
    "tree": "木",
    "earth": "土",
    "heart": "心",
    "eye": "眼睛",
    "person": "人",
    "woman": "女人",
    "man": "人",
    "bird": "鸟",
    "fish": "鱼",
    "roof": "房顶",
    "father": "爸爸",
    "grass": "草",
}


def evolution_type_label(etype: str | None) -> str | None:
    if not etype:
        return None
    return EVOLUTION_TYPE_LABELS.get(etype)


def _translate_english_hint(hint: str, character: str) -> str:
    if not hint:
        return ""
    h = hint.replace("\xa0", " ").strip()
    # 已是中文为主则直接返回
    chinese_chars = sum(1 for c in h if "\u4e00" <= c <= "\u9fff")
    if chinese_chars >= len(h) // 3:
        return h

    for pattern, repl in _EN_PATTERNS:
        h = re.sub(pattern, repl, h, flags=re.IGNORECASE)

    lower = h.lower()
    for en, zh in _EN_WORD_MAP.items():
        if en in lower:
            h = re.sub(re.escape(en), zh, h, flags=re.IGNORECASE)

    # 提取 hint 中的汉字部件
    parts_in_hint = [c for c in h if "\u4e00" <= c <= "\u9fff" and c != character]
    if parts_in_hint and chinese_chars < 3:
        named = "、".join(f"「{p}」" for p in list(dict.fromkeys(parts_in_hint))[:3])
        return f"古时候由{named}组合而成——慢慢写成今天的「{character}」。"

    if len(h) > 80:
        h = h[:77] + "…"
    return f"古时候的字像一幅小画——{h}，后来写成「{character}」。"


def _pictophonetic_hint(
    character: str,
    etymology: dict,
    components: list[str] | None,
) -> str:
    from hanzi_decomposition import COMPONENT_KID_NAMES

    semantic = etymology.get("semantic") or ""
    phonetic = etymology.get("phonetic") or ""
    raw_hint = etymology.get("hint") or ""

    sem = str(semantic) if semantic else ""
    ph = str(phonetic) if phonetic else ""

    if components and len(components) >= 2:
        left, right = components[0], components[1]
        sem_part = left if sem and (sem in left or left in sem) else (sem or left)
        ph_part = right if ph and (ph in right or right in ph) else (ph or right)
        sem_name = COMPONENT_KID_NAMES.get(sem_part, f"「{sem_part}」")
        ph_name = f"「{ph_part}」" if ph_part else ""
        if ph_name:
            return (
                f"左边{sem_name}表示意思，右边{ph_name}帮助读音——"
                f"合在一起就是「{character}」，这是形声字！"
            )
        return f"左边{sem_name}表示意思——慢慢写成「{character}」。"

    if raw_hint and raw_hint in _SEMANTIC_HINT_ZH:
        return (
            f"跟{_SEMANTIC_HINT_ZH[raw_hint]}有关，加上表音的部分——"
            f"写成今天的「{character}」！"
        )
    return f"一部分表意思、一部分表读音——合起来是形声字「{character}」！"


def make_evolution_hint(
    character: str,
    etymology: dict | None,
    components: list[str] | None = None,
) -> tuple[str | None, str | None]:
    """
    返回 (演变类型中文标签, 演变讲解)。
    优先用手工 Level1 文案，其次根据 Make Me A Hanzi 字源生成。
    """
    if character in LEVEL1_EVOLUTION_HINTS:
        etype = None
        if etymology:
            etype = evolution_type_label(etymology.get("type"))
        if not etype and components:
            etype = "形声" if len(components) == 2 else "会意"
        elif not etype:
            etype = "象形"
        return etype, LEVEL1_EVOLUTION_HINTS[character]

    if not etymology:
        return None, None

    etype = evolution_type_label(etymology.get("type"))
    raw_hint = etymology.get("hint")

    if etymology.get("type") == "pictophonetic":
        hint = _pictophonetic_hint(character, etymology, components)
        return etype, hint

    if isinstance(raw_hint, str) and raw_hint.strip():
        translated = _translate_english_hint(raw_hint, character)
        if etype == "象形":
            return etype, f"像一幅小画：{translated}"
        return etype, translated

    if etype:
        fallback = {
            "象形": f"这个字像一幅小画——多看几眼，就能记住「{character}」啦！",
            "会意": f"几个部分合在一起表达意思——就是「{character}」！",
            "形声": f"一部分表意思、一部分表读音——是形声字「{character}」！",
        }
        return etype, fallback.get(etype)

    return None, None


def all_evolution_hints() -> dict[str, str]:
    return dict(LEVEL1_EVOLUTION_HINTS)
