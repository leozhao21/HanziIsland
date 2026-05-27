#!/usr/bin/env python3
"""生成识字岛四级字库 JSON（Level 1=100, 2=300, 3=500, 4=1000）。"""

from __future__ import annotations

import json
import re
from pathlib import Path

try:
    from pypinyin import Style, lazy_pinyin
except ImportError:
    lazy_pinyin = None

ROOT = Path(__file__).resolve().parents[1] / "HanziIsland" / "Resources"
SUPPLEMENT = Path(__file__).resolve().parent / "common_chars_supplement.txt"

# Level 1：100 个生活常用字（PRD 示例 + 学龄前高频）
LEVEL_1 = list(
    "我你他她爸妈家来去看出吃喝跑跳笑哭大小多少"
    "天地日月水火木金土山"
    "头手足心眼耳口"
    "狗猫马牛羊鸡"
    "鱼鸟虫"
    "花草树叶"
    "米瓜豆菜饭"
    "车门窗床"
    "衣笔纸书包"
    "桌椅灯"
    "年月明昨早晚"
    "春夏秋东"
    "南西北上下左右"
    "里前高低"
    "长短"
    "红黑白"
    "好坏新旧"
    "快慢"
    "开关"
    "想说听"
    "叫走坐站"
    "睡起玩学写读"
    "拿放给"
    "要能"
    "不没有"
    "是"
    "一二三四五"
    "六七八九十"
    "个只"
)

# Level 2：儿童阅读高频（去重后补足 300）
LEVEL_2 = list(
    "江河湖海雨雪风雷电云"
    "森林田野园"
    "桃杏梨苹果香蕉"
    "稻麦茶糖盐油"
    "鸡鸭鹅猪兔"
    "虎熊狼象鹿"
    "龟蛙蝶蜂蚂蚁"
    "船飞机火车"
    "路桥街城镇乡村"
    "学校老师同学朋友"
    "哥哥姐弟妹"
    "爷爷奶奶外公外婆"
    "身体头发脸鼻舌"
    "胳膊腿肚背腰"
    "病痛医护士药"
    "颜色青紫灰棕"
    "零百千万亿"
    "第每各同"
    "很太更最"
    "也还就又才"
    "喜欢爱恨"
    "帮助照顾"
    "工作劳动"
    "运动比赛"
    "唱歌跳舞"
    "画画写字"
    "做饭洗衣"
    "打扫整理"
    "买花钱元"
    "送接等待"
    "找丢失"
    "进出入回"
    "推拉打抱"
    "爬游飞"
    "冷暖温凉"
    "轻重深浅"
    "远近宽窄"
    "厚薄软硬"
    "干净整齐"
    "美丽漂亮"
    "聪明勇敢"
    "诚实礼貌"
    "安全危险"
    "高兴难过"
    "害怕生气"
    "星星"
    "早晨中午夜晚"
    "星期周末"
    "节日生日"
    "礼物玩具"
    "游戏故事"
    "电影电视"
    "电话电脑"
    "照片地图"
    "国旗"
    "工人农民"
    "警察"
    "科学家"
    "英雄"
    "祖国北京"
    "长城"
    "春节元宵"
    "端午中秋"
    "清明"
    "植树"
    "环境"
    "节约用水"
    "爱护动物"
    "尊重老人"
    "团结友爱"
    "刻苦学习"
    "天天向上"
    "鸟鱼狗猫车书笔"
)

# 单字补充（从上面词组拆出及扩展）
LEVEL_2_EXTRA = list(
    "鸟鱼狗猫车书笔江河湖海雨雪风雷电云"
    "森林木禾苗芽果实种子"
    "街市店铺商场价格"
    "票元角分"
    "姓名称呼"
    "男女老少"
    "胖瘦高矮"
    "快慢远近"
    "深浅明暗"
    "甜苦辣酸"
    "香臭"
    "软硬"
    "干湿"
    "新旧"
    "真假"
    "对错"
    "是非"
    "加减乘除"
    "等于"
    "左右前后"
    "内外中间"
    "旁边"
    "附近"
    "到处"
    "永远"
    "已经"
    "正在"
    "将要"
    "可能"
    "应该"
    "必须"
    "愿意"
    "希望"
    "相信"
    "记得"
    "忘记"
    "明白"
    "知道"
    "认识"
    "懂得"
    "学习"
    "练习"
    "复习"
    "考试"
    "成绩"
    "进步"
    "努力"
    "认真"
    "仔细"
    "马虎"
    "粗心"
)

CUSTOM_SENTENCES: dict[str, str] = {
    "喝": "天热的时候要多喝水。",
    "跑": "小明每天都去操场跑步。",
    "家": "放学后我要回家。",
    "妈": "妈妈给我做晚饭。",
    "猫": "我家的猫喜欢晒太阳。",
    "我": "我是小学生。",
    "你": "你在做什么？",
    "他": "他在看书。",
    "她": "她在画画。",
    "爸": "爸爸带我去公园。",
    "看": "我喜欢看动画片。",
    "吃": "中午我吃米饭。",
    "笑": "听到笑话我们都笑了。",
    "哭": "弟弟摔倒了在哭。",
    "大": "这棵树好大啊。",
    "小": "我有一只小狗。",
    "多": "花园里有很多花。",
    "少": "今天作业很少。",
    "狗": "小狗在院子里玩。",
    "鸟": "树上有一只小鸟。",
    "鱼": "鱼缸里游着小鱼。",
    "花": "春天公园里开满花。",
    "草": "草坪上的草很绿。",
    "树": "大树下很凉快。",
    "车": "爸爸开车送我上学。",
    "书": "我喜欢看故事书。",
    "笔": "我用铅笔写字。",
    "去": "我们一起去上学。",
    "来": "朋友来我家玩。",
    "跳": "孩子们在草地上跳。",
    "学": "我在学校学汉字。",
    "写": "我会写自己的名字。",
    "读": "每天晚上爸爸给我读书。",
    "玩": "下课我们一起玩。",
    "睡": "晚上九点我要睡觉。",
    "起": "早上七点起床。",
    "坐": "请坐在椅子上。",
    "站": "排队时要站好。",
    "走": "我们走路上学。",
    "说": "有问题要大胆说。",
    "听": "上课认真听老师讲。",
    "好": "今天天气真好。",
    "雨": "下雨了要带雨伞。",
    "雪": "下雪了我们堆雪人。",
    "春": "春天花开了。",
    "夏": "夏天我们去游泳。",
    "秋": "秋天树叶变黄了。",
    "冬": "冬天会下大雪。",
}


def unique_hanzi(text: str) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for c in text:
        if "\u4e00" <= c <= "\u9fff" and c not in seen:
            seen.add(c)
            out.append(c)
    return out


def load_supplement() -> str:
    if SUPPLEMENT.exists():
        return SUPPLEMENT.read_text(encoding="utf-8")
    return (
        "的一是在不了有和人这中大为上个国我以要他时来用们生到作地于出就分对成会可主发年动同工也能下过子说产种面而方后多定行学法所民得经十三之进着等部度家电力里如水化高自二理起小物现实加量都两体制机当使点从业本去把性好应开它合还因由其些然前外天政四日那社义事平形相全表间样与关各重新线内数正心反你明看原又么利比或但质气第向道命此变条只没结解问意建月公无系军很情者最立代想已通并提直题党程展五果料象员革位入常文总次品式活设及管特件长求老头基资边流路级少图山统接知较将组见计别她手角期根论运农指几九区强放决西被干做必战先回则任取据处队南给色光门即保治北造百规热领七海口东导器压志世金增争济阶油思术极交受联什认六共权收证改清己美再采转单风切打白教速花带安场身车例真务具万每目至达走积示议声报斗完类八离华名确才科张信马节话米整空元况今集温传土许步群广石记需段研界拉林律叫且究观越织装影算低持音众书布复容儿须际商非验连断深难近矿千周委素技备半办青省列习响约支般史感劳便团往酸历市克何除消构府称太准精值号率族维划选标写存候毛亲快效斯院查江型眼王按格养易置派层片始却专状育厂京识适属圆包火住调满县局照参红细引听该铁价严龙飞"
        "习医准备赏拥刺拥闪避奔恢聘拆摸聪腕挖抽畅饮慰贪挣挖肠脆抛饰脊畏吻默窃肌拦玻忌猎袍惯扩括扫梯摆烂棉棒棕橡惠赠岩灰宫毁筑舆聪翼漾鹃锋瓣露哀愁憾慨愤鼎鼓锤铸锻镀镇碑础磅磁磨祥禄禅祸禧秩穆穴窑窒窖窗窘窜窝窟窥窿竣笃筑策筛筒筏答筋筝筷筹签简箍箕算箩管箫箭箱篇篓篙篡篮篱篷簇簸簿籍糯糕糖糙糜糟糠懦豁臀臂臊臣卧虱卵驯驰驱驳驴驶驹驻驼驾驿骂骄骆骇骑骗骚骡骤骨髓鬓鬼魁魂魄魏魔鲜鸽鸾鸿鹂鹃鹄鹅鹘鹜鹞鹤鹦鹰麋麒麓麝麟黏黍黎黛"
    )


def pinyin_for(ch: str) -> str:
    if lazy_pinyin:
        return lazy_pinyin(ch, style=Style.TONE)[0]
    return ch


def make_sentence(ch: str) -> str:
    if ch in CUSTOM_SENTENCES:
        s = CUSTOM_SENTENCES[ch]
        if len(s) <= 20:
            return s
    candidates = [
        f"我喜欢{ch}。",
        f"我会写{ch}字。",
        f"今天学了{ch}。",
        f"妈妈教我认{ch}。",
        f"课本上有{ch}字。",
        f"动物园里有{ch}。",
        f"桌上放着{ch}。",
    ]
    for s in candidates:
        if ch in s and len(s) <= 20:
            return s
    return f"我认识了{ch}。"[:20]


def make_entry(ch: str, level: int, index: int) -> dict:
    return {
        "id": f"l{level}_{index:04d}_{ord(ch):x}",
        "character": ch,
        "pinyin": pinyin_for(ch),
        "meaning": f"常用汉字「{ch}」",
        "sentence": make_sentence(ch),
        "level": level,
        "image": None,
        "audio": None,
        "strokeAnimation": None,
    }


def fill_to(target: int, primary: list[str], pool: str, exclude: set[str]) -> list[str]:
    result: list[str] = []
    for c in primary:
        if c not in exclude and c not in result:
            result.append(c)
    for c in unique_hanzi(pool):
        if len(result) >= target:
            break
        if c not in exclude and c not in result:
            result.append(c)
    if len(result) < target:
        raise SystemExit(f"字库不足：需要 {target}，仅得到 {len(result)}")
    return result[:target]


def main() -> None:
    pool = load_supplement()
    exclude: set[str] = set()

    l1 = fill_to(100, LEVEL_1, "", exclude)
    exclude.update(l1)

    l2 = fill_to(300, LEVEL_2 + LEVEL_2_EXTRA, pool, exclude)
    exclude.update(l2)

    l3 = fill_to(500, "", pool, exclude)
    exclude.update(l3)

    l4 = fill_to(1000, "", pool, exclude)

    ROOT.mkdir(parents=True, exist_ok=True)
    for level, chars in [(1, l1), (2, l2), (3, l3), (4, l4)]:
        path = ROOT / f"characters_level{level}.json"
        data = [make_entry(c, level, i) for i, c in enumerate(chars)]
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"{path.name}: {len(data)} 字")


if __name__ == "__main__":
    main()
