from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session
from .. import crud, models
from ..database import get_db
import json
from datetime import date, timedelta

router = APIRouter(
    prefix="/admin",
    tags=["admin"]
)

@router.get("/dashboard", response_class=HTMLResponse)
async def dashboard(secret: str, db: Session = Depends(get_db)):
    if secret != "TraeAdmin2026":
        raise HTTPException(status_code=403, detail="Unauthorized")
    
    # 1. 基础数据
    overview = crud.get_stats_overview(db)
    
    # 2. 趋势数据 (PV/UV)
    trend_data = crud.get_visit_trend(db, 7)
    trend_dates = [t.date for t in trend_data]
    trend_pv = [t.pv for t in trend_data]
    trend_uv = [t.uv for t in trend_data]
    
    # 3. 分布数据
    geo_data = crud.get_geo_distribution(db, 10)
    geo_chart_data = [{"name": g.geo_location, "value": g.count} for g in geo_data]
    
    os_data = crud.get_os_distribution(db)
    os_chart_data = [{"name": o.os, "value": o.count} for o in os_data]
    
    browser_data = crud.get_browser_distribution(db)
    browser_chart_data = [{"name": b.browser, "value": b.count} for b in browser_data]
    
    # 4. 最近访问日志
    recent_visits = crud.get_website_visits(db, 0, 20)
    
    html = f"""
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>DeskCare 数据监控看板</title>
        <!-- Tailwind CSS -->
        <script src="https://cdn.tailwindcss.com"></script>
        <!-- ECharts -->
        <script src="https://cdn.jsdelivr.net/npm/echarts@5.4.3/dist/echarts.min.js"></script>
        <style>
            body {{ background-color: #f3f4f6; font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif; }}
            .card {{ background: white; border-radius: 0.5rem; padding: 1.5rem; box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1); }}
            .stat-value {{ font-size: 1.875rem; font-weight: 700; color: #111827; }}
            .stat-label {{ font-size: 0.875rem; color: #6b7280; }}
            .chart-container {{ height: 400px; width: 100%; }}
        </style>
    </head>
    <body>
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            <h1 class="text-3xl font-bold text-gray-900 mb-8">DeskCare 数据监控看板</h1>
            
            <!-- 概览卡片 -->
            <div class="grid grid-cols-1 md:grid-cols-5 gap-4 mb-8">
                <div class="card">
                    <div class="stat-label">今日浏览量 (PV)</div>
                    <div class="stat-value text-blue-600">{overview['today_pv']}</div>
                </div>
                <div class="card">
                    <div class="stat-label">今日访客数 (UV)</div>
                    <div class="stat-value text-green-600">{overview['today_uv']}</div>
                </div>
                <div class="card">
                    <div class="stat-label">历史总浏览量</div>
                    <div class="stat-value">{overview['total_pv']}</div>
                </div>
                <div class="card">
                    <div class="stat-label">总下载量</div>
                    <div class="stat-value text-purple-600">{overview['total_downloads']}</div>
                </div>
                <div class="card">
                    <div class="stat-label">总用户数 (机器ID)</div>
                    <div class="stat-value text-indigo-600">{overview['total_users']}</div>
                </div>
            </div>
            
            <!-- 趋势图 -->
            <div class="card mb-8">
                <h2 class="text-xl font-semibold mb-4">近7天访问趋势</h2>
                <div id="trendChart" class="chart-container"></div>
            </div>
            
            <!-- 分布图 -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-8 mb-8">
                <div class="card">
                    <h2 class="text-xl font-semibold mb-4">访客地理分布 (Top 10)</h2>
                    <div id="geoChart" class="chart-container" style="height: 300px;"></div>
                </div>
                <div class="card">
                    <h2 class="text-xl font-semibold mb-4">操作系统分布</h2>
                    <div id="osChart" class="chart-container" style="height: 300px;"></div>
                </div>
                <div class="card">
                    <h2 class="text-xl font-semibold mb-4">浏览器分布</h2>
                    <div id="browserChart" class="chart-container" style="height: 300px;"></div>
                </div>
            </div>
            
            <!-- 详细日志表格 -->
            <div class="card">
                <h2 class="text-xl font-semibold mb-4">实时访问日志 (最近20条)</h2>
                <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">时间</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">IP / 地理位置</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">设备信息</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">来源 (Referrer)</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">路径</th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            {"".join([f'''
                            <tr>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{v.visited_at.strftime('%Y-%m-%d %H:%M:%S')}</td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                    <div>{v.ip_address}</div>
                                    <div class="text-xs text-gray-500">{v.geo_location}</div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                    {v.os or 'Unknown'} / {v.browser or 'Unknown'} <br>
                                    <span class="text-xs bg-gray-100 rounded px-1">{v.device_type or 'PC'}</span>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 max-w-xs truncate" title="{v.referrer}">{v.referrer or '-'}</td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{v.path}</td>
                            </tr>
                            ''' for v in recent_visits])}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <script>
            // 趋势图
            var trendChart = echarts.init(document.getElementById('trendChart'));
            var trendOption = {{
                tooltip: {{ trigger: 'axis' }},
                legend: {{ data: ['浏览量 (PV)', '访客数 (UV)'] }},
                grid: {{ left: '3%', right: '4%', bottom: '3%', containLabel: true }},
                xAxis: {{ type: 'category', boundaryGap: false, data: {json.dumps(trend_dates)} }},
                yAxis: {{ type: 'value' }},
                series: [
                    {{ name: '浏览量 (PV)', type: 'line', data: {json.dumps(trend_pv)}, smooth: true, color: '#2563EB' }},
                    {{ name: '访客数 (UV)', type: 'line', data: {json.dumps(trend_uv)}, smooth: true, color: '#10B981' }}
                ]
            }};
            trendChart.setOption(trendOption);

            // 地理分布图
            var geoChart = echarts.init(document.getElementById('geoChart'));
            var geoOption = {{
                tooltip: {{ trigger: 'item' }},
                series: [
                    {{
                        name: '地理位置',
                        type: 'pie',
                        radius: '70%',
                        data: {json.dumps(geo_chart_data)},
                        emphasis: {{ itemStyle: {{ shadowBlur: 10, shadowOffsetX: 0, shadowColor: 'rgba(0, 0, 0, 0.5)' }} }}
                    }}
                ]
            }};
            geoChart.setOption(geoOption);

            // OS 分布图
            var osChart = echarts.init(document.getElementById('osChart'));
            var osOption = {{
                tooltip: {{ trigger: 'item' }},
                series: [
                    {{
                        name: '操作系统',
                        type: 'pie',
                        radius: ['40%', '70%'],
                        avoidLabelOverlap: false,
                        itemStyle: {{ borderRadius: 10, borderColor: '#fff', borderWidth: 2 }},
                        data: {json.dumps(os_chart_data)}
                    }}
                ]
            }};
            osChart.setOption(osOption);
            
            // Browser 分布图
            var browserChart = echarts.init(document.getElementById('browserChart'));
            var browserOption = {{
                tooltip: {{ trigger: 'item' }},
                series: [
                    {{
                        name: '浏览器',
                        type: 'pie',
                        radius: ['40%', '70%'],
                        avoidLabelOverlap: false,
                        itemStyle: {{ borderRadius: 10, borderColor: '#fff', borderWidth: 2 }},
                        data: {json.dumps(browser_chart_data)}
                    }}
                ]
            }};
            browserChart.setOption(browserOption);

            // 响应式调整
            window.addEventListener('resize', function() {{
                trendChart.resize();
                geoChart.resize();
                osChart.resize();
                browserChart.resize();
            }});
        </script>
    </body>
    </html>
    """
    return html
