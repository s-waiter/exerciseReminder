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

def format_duration(seconds):
    if not seconds:
        return '<span class="text-gray-400">-</span>'
    if seconds < 60:
        return f"{seconds}s"
    m, s = divmod(seconds, 60)
    if m < 60:
        return f"{m}m {s}s"
    h, m = divmod(m, 60)
    return f"{h}h {m}m"

@router.get("/dashboard", response_class=HTMLResponse)
async def dashboard(secret: str, db: Session = Depends(get_db)):
    if secret != "TraeAdmin2026":
        raise HTTPException(status_code=403, detail="Unauthorized")
    
    # 1. 基础数据
    overview = crud.get_stats_overview(db)
    
    # 2. 趋势数据 (PV/UV) - 30天
    trend_data = crud.get_visit_trend(db, 30)
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
    recent_visits = crud.get_website_visits(db, 0, 50) # Increased to 50
    
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
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
        <style>
            body {{ background-color: #f8fafc; font-family: 'Inter', 'PingFang SC', 'Microsoft YaHei', sans-serif; }}
            .card {{ background: white; border-radius: 1rem; padding: 1.5rem; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03); border: 1px solid #e2e8f0; transition: all 0.3s ease; }}
            .card:hover {{ box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05), 0 4px 6px -2px rgba(0, 0, 0, 0.025); }}
            .stat-value {{ font-size: 2rem; font-weight: 700; color: #0f172a; line-height: 1; margin-top: 0.5rem; }}
            .stat-label {{ font-size: 0.875rem; font-weight: 500; color: #64748b; letter-spacing: 0.025em; text-transform: uppercase; }}
            .chart-container {{ height: 400px; width: 100%; }}
            th {{ background-color: #f8fafc; color: #475569; font-weight: 600; font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em; }}
            td {{ color: #334155; }}
            .badge {{ padding: 0.25rem 0.5rem; border-radius: 9999px; font-size: 0.75rem; font-weight: 500; }}
            .badge-success {{ bg-green-100 text-green-800; background-color: #dcfce7; color: #166534; }}
            .badge-gray {{ bg-gray-100 text-gray-800; background-color: #f1f5f9; color: #475569; }}
        </style>
    </head>
    <body class="bg-slate-50 text-slate-900">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
            <div class="flex justify-between items-center mb-10">
                <div>
                    <h1 class="text-3xl font-bold text-slate-900 tracking-tight">DeskCare 监控中心</h1>
                    <p class="text-slate-500 mt-2">实时数据分析与运营概览</p>
                </div>
                <div class="text-sm text-slate-400">
                    最后更新: {date.today().strftime('%Y-%m-%d')}
                </div>
            </div>
            
            <!-- 概览卡片 -->
            <div class="grid grid-cols-1 md:grid-cols-5 gap-6 mb-10">
                <div class="card border-l-4 border-blue-500">
                    <div class="stat-label">今日浏览量 (PV)</div>
                    <div class="stat-value text-blue-600">{overview['today_pv']}</div>
                </div>
                <div class="card border-l-4 border-emerald-500">
                    <div class="stat-label">今日访客数 (UV)</div>
                    <div class="stat-value text-emerald-600">{overview['today_uv']}</div>
                </div>
                <div class="card border-l-4 border-violet-500">
                    <div class="stat-label">历史总浏览量</div>
                    <div class="stat-value text-slate-700">{overview['total_pv']}</div>
                </div>
                <div class="card border-l-4 border-amber-500">
                    <div class="stat-label">总下载量</div>
                    <div class="stat-value text-amber-600">{overview['total_downloads']}</div>
                </div>
                <div class="card border-l-4 border-indigo-500">
                    <div class="stat-label">总用户数 (机器ID)</div>
                    <div class="stat-value text-indigo-600">{overview['total_users']}</div>
                </div>
            </div>
            
            <!-- 趋势图 -->
            <div class="card mb-10">
                <div class="flex items-center justify-between mb-6">
                    <h2 class="text-xl font-bold text-slate-800">近30天访问趋势</h2>
                    <span class="text-sm text-slate-400">PV / UV</span>
                </div>
                <div id="trendChart" class="chart-container" style="height: 450px;"></div>
            </div>
            
            <!-- 分布图 -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-10">
                <div class="card">
                    <h2 class="text-lg font-bold text-slate-800 mb-6">访客地理分布 (Top 10)</h2>
                    <div id="geoChart" class="chart-container" style="height: 350px;"></div>
                </div>
                <div class="card">
                    <h2 class="text-lg font-bold text-slate-800 mb-6">操作系统分布</h2>
                    <div id="osChart" class="chart-container" style="height: 350px;"></div>
                </div>
                <div class="card">
                    <h2 class="text-lg font-bold text-slate-800 mb-6">浏览器分布</h2>
                    <div id="browserChart" class="chart-container" style="height: 350px;"></div>
                </div>
            </div>
            
            <!-- 详细日志表格 -->
            <div class="card overflow-hidden">
                <div class="flex items-center justify-between mb-6">
                    <h2 class="text-xl font-bold text-slate-800">实时访问日志 (最近50条)</h2>
                    <div class="flex gap-2">
                         <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                           <span class="w-1.5 h-1.5 bg-green-500 rounded-full mr-1.5"></span>
                           已下载
                         </span>
                         <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                           <span class="w-1.5 h-1.5 bg-gray-400 rounded-full mr-1.5"></span>
                           未下载
                         </span>
                    </div>
                </div>
                <div class="overflow-x-auto -mx-6">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50/50">
                            <tr>
                                <th class="px-6 py-4 text-left">时间</th>
                                <th class="px-6 py-4 text-left">IP / 地理位置</th>
                                <th class="px-6 py-4 text-left">停留时长</th>
                                <th class="px-6 py-4 text-left">设备信息</th>
                                <th class="px-6 py-4 text-left">来源 (Referrer)</th>
                                <th class="px-6 py-4 text-left">状态</th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-100">
                            {"".join([f'''
                            <tr class="hover:bg-slate-50 transition-colors">
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 font-mono">
                                    {v.visited_at.strftime('%Y-%m-%d')}<br>
                                    <span class="text-xs text-gray-400">{v.visited_at.strftime('%H:%M:%S')}</span>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                    <div class="font-medium text-slate-700">{v.ip_address}</div>
                                    <div class="text-xs text-gray-500 mt-0.5">{v.geo_location}</div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-600">
                                    {format_duration(v.duration_seconds)}
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                    <div class="flex items-center gap-2">
                                        <span>{v.os or 'Unknown'}</span>
                                        <span class="text-gray-300">/</span>
                                        <span>{v.browser or 'Unknown'}</span>
                                    </div>
                                    <div class="mt-1">
                                        <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-slate-100 text-slate-800">
                                            {v.device_type or 'PC'}
                                        </span>
                                    </div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 max-w-xs truncate">
                                    <div title="{v.referrer or '-'}">{v.referrer or '-'}</div>
                                    <div class="text-xs text-gray-400 mt-0.5" title="{v.path}">Path: {v.path}</div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm">
                                    {f'<span class="badge badge-success inline-flex items-center gap-1">✅ 已下载 <span class="opacity-75 text-[10px]">{v.downloaded_version}</span></span>' if v.is_downloaded else '<span class="badge badge-gray">未下载</span>'}
                                </td>
                            </tr>
                            ''' for v in recent_visits])}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <script>
            // 通用图表配置
            const commonGrid = {{ left: '3%', right: '4%', bottom: '3%', containLabel: true }};
            const commonTooltip = {{ 
                trigger: 'axis',
                backgroundColor: 'rgba(255, 255, 255, 0.95)',
                borderColor: '#e2e8f0',
                borderWidth: 1,
                textStyle: {{ color: '#1e293b' }},
                extraCssText: 'box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);'
            }};

            // 趋势图
            var trendChart = echarts.init(document.getElementById('trendChart'));
            var trendOption = {{
                tooltip: commonTooltip,
                legend: {{ 
                    data: ['浏览量 (PV)', '访客数 (UV)'],
                    bottom: 0,
                    itemGap: 20
                }},
                grid: {{ ...commonGrid, bottom: '10%' }},
                xAxis: {{ 
                    type: 'category', 
                    boundaryGap: false, 
                    data: {json.dumps(trend_dates)},
                    axisLine: {{ lineStyle: {{ color: '#cbd5e1' }} }},
                    axisLabel: {{ color: '#64748b' }}
                }},
                yAxis: {{ 
                    type: 'value',
                    splitLine: {{ lineStyle: {{ color: '#f1f5f9' }} }},
                    axisLabel: {{ color: '#64748b' }}
                }},
                series: [
                    {{ 
                        name: '浏览量 (PV)', 
                        type: 'line', 
                        data: {json.dumps(trend_pv)}, 
                        smooth: true, 
                        showSymbol: false,
                        color: '#3b82f6',
                        lineStyle: {{ width: 3 }},
                        areaStyle: {{
                            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                                {{ offset: 0, color: 'rgba(59, 130, 246, 0.2)' }},
                                {{ offset: 1, color: 'rgba(59, 130, 246, 0.0)' }}
                            ])
                        }}
                    }},
                    {{ 
                        name: '访客数 (UV)', 
                        type: 'line', 
                        data: {json.dumps(trend_uv)}, 
                        smooth: true, 
                        showSymbol: false,
                        color: '#10b981',
                        lineStyle: {{ width: 3 }},
                        areaStyle: {{
                            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                                {{ offset: 0, color: 'rgba(16, 185, 129, 0.2)' }},
                                {{ offset: 1, color: 'rgba(16, 185, 129, 0.0)' }}
                            ])
                        }}
                    }}
                ]
            }};
            trendChart.setOption(trendOption);

            // 饼图通用配置
            const pieTooltip = {{
                trigger: 'item',
                backgroundColor: 'rgba(255, 255, 255, 0.95)',
                formatter: '{{b}}: {{c}} ({{d}}%)'
            }};
            
            const pieSeriesCommon = {{
                type: 'pie',
                radius: ['40%', '70%'],
                avoidLabelOverlap: false,
                itemStyle: {{ borderRadius: 8, borderColor: '#fff', borderWidth: 2 }},
                label: {{ show: false, position: 'center' }},
                emphasis: {{ 
                    label: {{ show: true, fontSize: '18', fontWeight: 'bold' }},
                    itemStyle: {{ shadowBlur: 10, shadowOffsetX: 0, shadowColor: 'rgba(0, 0, 0, 0.2)' }}
                }}
            }};

            // 地理分布图
            var geoChart = echarts.init(document.getElementById('geoChart'));
            geoChart.setOption({{
                tooltip: pieTooltip,
                series: [{{
                    ...pieSeriesCommon,
                    name: '地理位置',
                    data: {json.dumps(geo_chart_data)},
                    color: ['#6366f1', '#8b5cf6', '#d946ef', '#ec4899', '#f43f5e', '#f97316', '#eab308', '#84cc16', '#22c55e', '#06b6d4']
                }}]
            }});

            // OS 分布图
            var osChart = echarts.init(document.getElementById('osChart'));
            osChart.setOption({{
                tooltip: pieTooltip,
                series: [{{
                    ...pieSeriesCommon,
                    name: '操作系统',
                    data: {json.dumps(os_chart_data)},
                    color: ['#3b82f6', '#0ea5e9', '#64748b', '#94a3b8']
                }}]
            }});
            
            // Browser 分布图
            var browserChart = echarts.init(document.getElementById('browserChart'));
            browserChart.setOption({{
                tooltip: pieTooltip,
                series: [{{
                    ...pieSeriesCommon,
                    name: '浏览器',
                    data: {json.dumps(browser_chart_data)},
                    color: ['#10b981', '#14b8a6', '#06b6d4', '#0ea5e9']
                }}]
            }});

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
