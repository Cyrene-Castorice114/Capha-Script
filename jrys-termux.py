#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests
from PIL import Image, ImageDraw, ImageFont
import random
import os
from datetime import datetime
from io import BytesIO

# ========== 配置 ==========
API_URL = "https://www.loliapi.com/acg/pe/"
OUTPUT_PATH = "/data/data/com.termux/files/home/.capha/oracle_card.png"
# =========================

def get_bg_image():
    """从API获取背景图"""
    try:
        resp = requests.get(API_URL, timeout=10)
        if resp.status_code == 200:
            content_type = resp.headers.get('content-type', '')
            if 'image' in content_type:
                return Image.open(BytesIO(resp.content)).convert("RGBA")
            try:
                data = resp.json()
                img_url = data.get('url') or data.get('imgurl') or data.get('img')
                if img_url:
                    img_resp = requests.get(img_url, timeout=10)
                    return Image.open(BytesIO(img_resp.content)).convert("RGBA")
            except:
                pass
    except Exception as e:
        print(f"获取背景图失败: {e}")
    # 备用背景：深色古风底色
    img = Image.new("RGB", (1080, 1920), color=(30, 25, 45))
    draw = ImageDraw.Draw(img)
    for i in range(1920):
        r = 30 + int(i/1920 * 40)
        g = 25 + int(i/1920 * 30)
        b = 45 + int(i/1920 * 35)
        draw.line([(0,i), (1080,i)], fill=(r,g,b))
    return img.convert("RGBA")

def generate_oracle_content():
    """生成运势内容（完全参照图片格式）"""
    today = datetime.now().strftime("%Y/%m/%d")
    
    # 标题组合（大吉+好运+财运+智慧 这种格式）
    title_parts = random.choice([
        ["大吉", "好运", "财运", "智慧"],
        ["上吉", "顺遂", "富贵", "安康"],
        ["大吉", "福气", "财源", "亨通"],
        ["吉昌", "如意", "纳福", "增慧"]
    ])
    title = " + ".join(title_parts)
    
    # 第一行诗句
    line1_list = [
        "天高任鸟飞，得意扬眉，智慧卓绝，财富伴随",
        "云开见月明，心旷神怡，福星高照，万事顺遂",
        "春风拂面来，意气风发，才思泉涌，好运连连"
    ]
    line1 = random.choice(line1_list)
    
    # 第二行详细运势
    line2_list = [
        "人情融洽财运佳，才智兼备福寿长，心胸宽广逢贵人，如虎添翼势飞扬",
        "和气生财路自宽，慧眼识途运不偏，肚量如海纳百川，乘风破浪济沧海",
        "厚德载物福泽深，智圆行方运道真，虚怀若谷交挚友，鹏程万里展宏图"
    ]
    line2 = random.choice(line2_list)
    
    # 警示语
    warning_list = [
        "但要注意心浮气躁，防止骄傲自满，切勿贪婪无厌，以免因贪失义，贻误大好前程",
        "谨记谦虚谨慎，莫因小利失大义，戒骄戒躁，居安思危，方能长久保平安",
        "得意之时需防失意，顺境之中当思逆境，保持平常心，方能行稳致远"
    ]
    warning = random.choice(warning_list)
    
    return {
        "date": today,
        "title": title,
        "line1": line1,
        "line2": line2,
        "warning": warning
    }

def wrap_text(text, max_len=22):
    """将长文本按指定长度换行"""
    lines = []
    while len(text) > max_len:
        # 尽量在标点符号处断开
        split_pos = max_len
        for i in range(max_len, max(0, max_len-5), -1):
            if i < len(text) and text[i] in "，。、；：":
                split_pos = i + 1
                break
        lines.append(text[:split_pos])
        text = text[split_pos:]
    if text:
        lines.append(text)
    return lines

def add_text_to_image(img, content):
    """添加横排居中古风文字"""
    draw = ImageDraw.Draw(img)
    width, height = img.size
    
    # 加载中文字体
    font_paths = [
        "/system/fonts/NotoSansCJK-Regular.ttc",
        "/system/fonts/DroidSansFallback.ttf",
        "/data/data/com.termux/files/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
    ]
    fonts = {}
    for fp in font_paths:
        if os.path.exists(fp):
            try:
                fonts['date'] = ImageFont.truetype(fp, 48)
                fonts['title'] = ImageFont.truetype(fp, 88)
                fonts['verse'] = ImageFont.truetype(fp, 52)
                fonts['detail'] = ImageFont.truetype(fp, 46)
                fonts['warning'] = ImageFont.truetype(fp, 40)
                fonts['footer'] = ImageFont.truetype(fp, 36)
                break
            except:
                pass
    if not fonts:
        fonts = {k: ImageFont.load_default() for k in ['date','title','verse','detail','warning','footer']}
    
    def draw_centered(text, y, font_key, fill_color=(255,240,200,255), shadow=True):
        """绘制居中文字，可选阴影"""
        font = fonts[font_key]
        try:
            bbox = draw.textbbox((0,0), text, font=font)
            tw = bbox[2] - bbox[0]
        except AttributeError:
            tw, _ = draw.textsize(text, font=font)
        x = (width - tw) // 2
        if shadow:
            draw.text((x+3, y+3), text, font=font, fill=(0,0,0,100))
        draw.text((x, y), text, font=font, fill=fill_color)
        return y + (bbox[3]-bbox[1]) if 'bbox' in dir() else y + 70
    
    def draw_multiline(text, y, font_key, fill_color=(255,240,200,255), max_len=22):
        """绘制多行居中文本"""
        lines = wrap_text(text, max_len)
        font = fonts[font_key]
        for line in lines:
            try:
                bbox = draw.textbbox((0,0), line, font=font)
                line_height = bbox[3] - bbox[1]
                tw = bbox[2] - bbox[0]
            except AttributeError:
                tw, line_height = draw.textsize(line, font=font)
            x = (width - tw) // 2
            draw.text((x, y), line, font=font, fill=fill_color)
            y += line_height + 15
        return y
    
    # 从顶部开始布局
    current_y = 180
    
    # 1. 日期（居中）
    current_y = draw_centered(content['date'], current_y, 'date', (200,180,120,255))
    current_y += 40
    
    # 2. 标题（大吉+好运+财运+智慧 大字）
    current_y = draw_centered(content['title'], current_y, 'title', (230,200,100,255))
    current_y += 50
    
    # 3. 第一行诗句
    current_y = draw_centered(content['line1'], current_y, 'verse', (220,200,150,255))
    current_y += 60
    
    # 4. 详细运势（可能多行）
    current_y = draw_multiline(content['line2'], current_y, 'detail', (210,190,140,255), max_len=20)
    current_y += 80
    
    # 5. 警示语（底部区域）
    warning_y = height - 280
    # 添加半透明底框
    warning_lines = wrap_text(content['warning'], 24)
    total_warning_height = len(warning_lines) * 50 + 40
    draw.rectangle([(40, warning_y-20), (width-40, warning_y + total_warning_height)], 
                   fill=(0,0,0,120))
    draw_multiline(content['warning'], warning_y, 'warning', (200,180,140,255), max_len=24)
    
    # 6. 免责声明
    disclaimer = "仅供娱乐 · 相信科学 · 请勿迷信"
    draw_centered(disclaimer, height - 120, 'footer', (150,140,110,220), shadow=False)
    
    # 7. Powered by DeepSeek
    draw_centered("Powered by DeepSeek", height - 70, 'footer', (180,160,120,220), shadow=False)
    
    return img

def main():
    print("✨ 开始生成古风运势卡片...")
    bg = get_bg_image()
    bg = bg.resize((1080, 1920), Image.Resampling.LANCZOS)
    content = generate_oracle_content()
    print("生成内容：")
    print(f"  日期: {content['date']}")
    print(f"  标题: {content['title']}")
    print(f"  第一句: {content['line1']}")
    print(f"  详细: {content['line2'][:50]}...")
    result = add_text_to_image(bg, content)
    result.save(OUTPUT_PATH)
    print(f"✅ 已保存至 {OUTPUT_PATH}")
    os.system(f"chafa {OUTPUT_PATH}")
    print("🎉 完成")

if __name__ == "__main__":
    main()