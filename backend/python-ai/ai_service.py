"""
AI老年健康守护系统 - Python AI 服务
提供：健康周报 LLM 生成、AI 健康分析、智能预警辅助
"""

import json
import os
from datetime import datetime, timedelta
from typing import Optional

# ============ 健康评分计算 ============

def calculate_health_score(weekly_data: dict) -> int:
    """根据周度数据计算健康评分 (0-100)"""
    score = 100
    
    # 异常事件扣分
    abnormal = weekly_data.get("abnormal_events", 0)
    if abnormal > 0:
        score -= min(abnormal * 5, 40)  # 最多扣 40 分
    
    # 签到率评估
    signin_rate = weekly_data.get("signin_rate", 100)
    if signin_rate < 50:
        score -= 20
    elif signin_rate < 80:
        score -= 10
    
    # 心率异常评估
    avg_hr = weekly_data.get("avg_heart_rate", 75)
    if avg_hr < 50 or avg_hr > 120:
        score -= 15
    
    # 血氧评估
    avg_spo2 = weekly_data.get("avg_spo2", 98)
    if avg_spo2 < 93:
        score -= 10
    elif avg_spo2 < 95:
        score -= 5
    
    return max(score, 0)


def generate_ai_summary(weekly_data: dict) -> str:
    """生成 AI 健康摘要"""
    score = weekly_data.get("health_score", calculate_health_score(weekly_data))
    abnormal = weekly_data.get("abnormal_events", 0)
    signin_rate = weekly_data.get("signin_rate", 100)
    avg_hr = weekly_data.get("avg_heart_rate", 0)
    avg_spo2 = weekly_data.get("avg_spo2", 0)
    
    parts = []
    
    # 总体评估
    if score >= 90:
        parts.append("本周长者整体健康状况良好，各项指标稳定。")
    elif score >= 70:
        parts.append("本周长者健康状况总体平稳，需关注部分指标波动。")
    elif score >= 50:
        parts.append("本周长者健康出现一些异常，建议加强关注。")
    else:
        parts.append("⚠️ 本周长者健康状况需要重视，建议安排巡访。")
    
    # 异常事件
    if abnormal > 0:
        parts.append(f"本周共发生 {abnormal} 次异常报警事件，请查看详情。")
    else:
        parts.append("本周无异常报警事件。")
    
    # 体征趋势
    if avg_hr > 0:
        if avg_hr < 60:
            parts.append(f"平均心率 {avg_hr:.0f} 次/分，偏低，建议关注。")
        elif avg_hr > 100:
            parts.append(f"平均心率 {avg_hr:.0f} 次/分，偏高，建议就医检查。")
        else:
            parts.append(f"平均心率 {avg_hr:.0f} 次/分，正常范围。")
    
    if avg_spo2 > 0:
        if avg_spo2 < 95:
            parts.append(f"平均血氧 {avg_spo2:.1f}%，偏低，请注意。")
        else:
            parts.append(f"平均血氧 {avg_spo2:.1f}%，正常。")
    
    # 签到
    if signin_rate >= 100:
        parts.append("本周每日签到全勤，生活规律。")
    elif signin_rate >= 80:
        parts.append("本周签到率良好。")
    else:
        parts.append(f"本周签到率 {signin_rate:.0f}%，建议关注老人作息。")
    
    return " ".join(parts)


def generate_suggestions(weekly_data: dict) -> str:
    """生成健康建议"""
    score = weekly_data.get("health_score", 0)
    suggestions = []
    
    if score < 60:
        suggestions.append("建议安排一次上门巡访，全面评估老人身体状况。")
    
    avg_hr = weekly_data.get("avg_heart_rate", 0)
    if avg_hr > 100 or avg_hr < 50:
        suggestions.append("建议带老人进行心电图检查，排除心脏问题。")
    
    avg_spo2 = weekly_data.get("avg_spo2", 0)
    if avg_spo2 < 95:
        suggestions.append("建议增加开窗通风频率，必要时进行肺功能检查。")
    
    signin_rate = weekly_data.get("signin_rate", 100)
    if signin_rate < 60:
        suggestions.append("老人签到不规律，建议子女增加日常联系频率。")
    
    total_steps = weekly_data.get("total_steps", 0)
    if total_steps < 1000:
        suggestions.append("本周活动量偏低，建议每天适量散步或室内活动。")
    elif total_steps > 50000:
        suggestions.append("本周活动量较大，注意充分休息。")
    
    if not suggestions:
        suggestions.append("继续保持现有良好生活习惯。")
        suggestions.append("建议每周至少联系老人 3 次，保持情感交流。")
    
    return "；".join(suggestions)


def analyze_trend(historical_data: list) -> dict:
    """分析体征趋势"""
    if not historical_data:
        return {"trend": "stable", "direction": "no_change", "detail": "数据不足"}
    
    recent = historical_data[-7:] if len(historical_data) >= 7 else historical_data
    earlier = historical_data[:-7] if len(historical_data) > 7 else []
    
    result = {"trend": "stable", "direction": "no_change"}
    
    # 心率趋势
    if recent and earlier:
        recent_avg = sum(d.get("heart_rate", 0) for d in recent) / len(recent)
        earlier_avg = sum(d.get("heart_rate", 0) for d in earlier) / len(earlier) if earlier else recent_avg
        
        if recent_avg > earlier_avg * 1.1:
            result["heart_rate_trend"] = "上升"
        elif recent_avg < earlier_avg * 0.9:
            result["heart_rate_trend"] = "下降"
        else:
            result["heart_rate_trend"] = "平稳"
    
    return result


def detect_anomaly(vital_data: dict, baseline: dict) -> Optional[dict]:
    """检测体征异常"""
    alerts = []
    
    hr = vital_data.get("heart_rate")
    if hr and baseline.get("heart_rate_baseline"):
        if hr < 40:
            alerts.append({"metric": "heart_rate", "level": "P1", "value": hr, 
                          "threshold": 40, "message": "心率过低"})
        elif hr > 140:
            alerts.append({"metric": "heart_rate", "level": "P1", "value": hr,
                          "threshold": 140, "message": "心率过高"})
    
    spo2 = vital_data.get("spo2")
    if spo2 and spo2 < 90:
        alerts.append({"metric": "spo2", "level": "P1", "value": spo2,
                       "threshold": 90, "message": "血氧过低"})
    
    temp = vital_data.get("temperature")
    if temp:
        if temp > 38.5:
            alerts.append({"metric": "temperature", "level": "P2", "value": temp,
                          "threshold": 38.5, "message": "体温过高"})
        elif temp < 35.0:
            alerts.append({"metric": "temperature", "level": "P2", "value": temp,
                          "threshold": 35.0, "message": "体温过低"})
    
    return alerts if alerts else None


# ============ 主入口 ============

if __name__ == "__main__":
    # 测试
    sample_data = {
        "abnormal_events": 2,
        "avg_heart_rate": 85,
        "avg_spo2": 97.5,
        "signin_rate": 85.7,
        "total_steps": 35000,
    }
    
    score = calculate_health_score(sample_data)
    summary = generate_ai_summary({**sample_data, "health_score": score})
    suggestions = generate_suggestions(sample_data)
    
    print(f"健康评分: {score}")
    print(f"AI摘要: {summary}")
    print(f"建议: {suggestions}")
