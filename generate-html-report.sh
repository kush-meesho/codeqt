#!/bin/bash
# generate-html-report.sh - Generate enhanced HTML report from CodeQT results with trend analysis

generate_html_report() {
    local results_dir="$1"
    local repo_name="$2"
    local branch_name="$3"
    local timestamp="$4"
    
    local codeql_file="$results_dir/codeql/results.json"
    local sonar_file="$results_dir/sonar/results.json"
    local output_file="$results_dir/combined-report.html"
    
    echo "🔧 Generating enhanced HTML report with trend analysis for $repo_name..."
    
    # Check if at least one results file exists
    if [ ! -f "$codeql_file" ] && [ ! -f "$sonar_file" ]; then
        echo "⚠️  No results files found. Skipping HTML report generation."
        return 1
    fi
    
    # Find previous analysis results for comparison
    local base_path="$HOME/Documents/codeqt/$repo_name/$branch_name"
    local previous_codeql_data="null"
    local previous_sonar_data="null"
    local previous_timestamp=""
    local previous_comparison_text=""
    
    echo "🔍 Looking for historical data in: $base_path"
    
    if [ -d "$base_path" ]; then
        # Find the most recent timestamp directory (excluding current one)
        local previous_dir=$(find "$base_path" -maxdepth 1 -type d -name "[0-9]*" | sort -nr | head -2 | tail -1)
        
        if [ -n "$previous_dir" ] && [ "$previous_dir" != "$base_path/$timestamp" ]; then
            previous_timestamp=$(basename "$previous_dir")
            echo "📊 Found previous analysis from timestamp: $previous_timestamp"
            
            local prev_codeql_file="$previous_dir/results/codeql/results.json"
            local prev_sonar_file="$previous_dir/results/sonar/results.json"
            
            if [ -f "$prev_codeql_file" ]; then
                echo "📈 Including previous CodeQL data for comparison..."
                previous_codeql_data=$(cat "$prev_codeql_file" | jq -c . 2>/dev/null || echo "null")
            fi
            
            if [ -f "$prev_sonar_file" ]; then
                echo "📈 Including previous SonarQube data for comparison..."
                previous_sonar_data=$(cat "$prev_sonar_file" | jq -c . 2>/dev/null || echo "null")
            fi
            
            # Format previous date
            local previous_date=$(date -r "$previous_timestamp" '+%b %d, %Y at %H:%M' 2>/dev/null || echo "Unknown")
            previous_comparison_text=" | Compared to: <strong>$previous_date</strong>"
        else
            echo "📊 No previous analysis found for comparison"
        fi
    fi
    
    # Read current JSON data safely
    local codeql_data="null"
    local sonar_data="null"
    
    if [ -f "$codeql_file" ]; then
        echo "📊 Including current CodeQL data..."
        codeql_data=$(cat "$codeql_file" | jq -c . 2>/dev/null || echo "null")
    fi
    
    if [ -f "$sonar_file" ]; then
        echo "📊 Including current SonarQube data..."
        sonar_data=$(cat "$sonar_file" | jq -c . 2>/dev/null || echo "null")
    fi
    
    # Generate the HTML report
    cat > "$output_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CodeQT Report - $repo_name</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            line-height: 1.6;
            color: #333;
            background: #f8f9fa;
            padding: 20px;
        }
        
        .container { max-width: 1400px; margin: 0 auto; }
        
        .header {
            background: linear-gradient(135deg, #007bff, #6610f2);
            color: white;
            padding: 2rem;
            border-radius: 8px;
            margin-bottom: 2rem;
            text-align: center;
        }
        
        .header h1 { font-size: 2rem; margin-bottom: 0.5rem; }
        .meta { opacity: 0.9; font-size: 0.9rem; }
        
        /* Tab Navigation */
        .tab-nav {
            display: flex;
            background: white;
            border-radius: 8px 8px 0 0;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 0;
        }
        
        .tab-nav button {
            background: none;
            border: none;
            padding: 1rem 2rem;
            cursor: pointer;
            font-size: 1rem;
            font-weight: 500;
            color: #6c757d;
            border-bottom: 3px solid transparent;
            transition: all 0.3s ease;
        }
        
        .tab-nav button.active {
            color: #007bff;
            border-bottom-color: #007bff;
            background: #f8f9fa;
        }
        
        .tab-nav button:hover {
            background: #f8f9fa;
            color: #007bff;
        }
        
        .tab-content {
            background: white;
            border-radius: 0 0 8px 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            min-height: 600px;
        }
        
        .tab-pane {
            display: none;
            padding: 2rem;
        }
        
        .tab-pane.active {
            display: block;
        }
        
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1rem;
            margin-bottom: 2rem;
        }
        
        .card {
            background: white;
            padding: 1.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-left: 4px solid;
        }
        
        .codeql { border-left-color: #28a745; }
        .sonar { border-left-color: #dc3545; }
        .combined { border-left-color: #ffc107; }
        .trend { border-left-color: #17a2b8; }
        
        .card h3 { margin-bottom: 1rem; color: #495057; }
        .stat { display: flex; justify-content: space-between; margin: 0.5rem 0; }
        .stat-value { font-weight: bold; padding: 0.25rem 0.5rem; border-radius: 4px; }
        
        .critical { background: #f8d7da; color: #721c24; }
        .high { background: #fff3cd; color: #856404; }
        .medium { background: #d1ecf1; color: #0c5460; }
        .low { background: #d4edda; color: #155724; }
        .info { background: #e2e3e5; color: #383d41; }
        .new-issue { background: #ffeaa7; color: #d63031; }
        .resolved { background: #00b894; color: white; }
        
        .filters {
            background: white;
            padding: 1rem;
            border-radius: 8px;
            margin-bottom: 1rem;
            display: flex;
            gap: 1rem;
            flex-wrap: wrap;
            align-items: center;
        }
        
        .filter-group { display: flex; flex-direction: column; gap: 0.25rem; }
        .filter-group label { font-size: 0.8rem; color: #666; }
        .filter-group input, .filter-group select {
            padding: 0.5rem;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 0.9rem;
        }
        
        .table-container {
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
        }
        
        th {
            background: #f8f9fa;
            padding: 1rem;
            text-align: left;
            font-weight: 600;
            border-bottom: 2px solid #dee2e6;
            font-size: 0.9rem;
        }
        
        td {
            padding: 0.75rem;
            border-bottom: 1px solid #eee;
            vertical-align: top;
            font-size: 0.85rem;
        }
        
        tr:hover { background: #f8f9fa; }
        
        .severity-badge {
            display: inline-block;
            padding: 0.2rem 0.4rem;
            border-radius: 3px;
            font-size: 0.7rem;
            font-weight: bold;
            text-transform: uppercase;
        }
        
        .tool-badge {
            display: inline-block;
            padding: 0.2rem 0.5rem;
            border-radius: 3px;
            font-size: 0.7rem;
            font-weight: 500;
            background: #e9ecef;
            color: #495057;
        }
        
        .trend-badge {
            display: inline-block;
            padding: 0.2rem 0.5rem;
            border-radius: 3px;
            font-size: 0.7rem;
            font-weight: 500;
            margin-left: 0.5rem;
        }
        
        .trend-badge.new {
            background: #ffeaa7;
            color: #d63031;
        }
        
        .trend-badge.resolved {
            background: #00b894;
            color: white;
        }
        
        .trend-summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin-bottom: 2rem;
        }
        
        .trend-chart {
            background: white;
            padding: 1.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
        }
        
        .trend-number {
            font-size: 2rem;
            font-weight: bold;
            margin: 0.5rem 0;
        }
        
        .trend-number.positive { color: #dc3545; }
        .trend-number.negative { color: #28a745; }
        .trend-number.neutral { color: #6c757d; }
        
        .file-path {
            font-family: 'Monaco', monospace;
            font-size: 0.75rem;
            color: #6c757d;
            max-width: 400px;
            word-break: break-all;
            line-height: 1.3;
            padding: 0.25rem 0;
        }
        
        .rule-code {
            font-family: 'Monaco', monospace;
            font-size: 0.8rem;
            background: #f1f3f4;
            padding: 0.2rem 0.4rem;
            border-radius: 3px;
        }
        
        .message {
            max-width: 400px;
            word-wrap: break-word;
            line-height: 1.4;
        }
        
        .line-num {
            font-family: 'Monaco', monospace;
            color: #6c757d;
            text-align: center;
        }
        
        .no-data {
            text-align: center;
            padding: 3rem;
            color: #6c757d;
            font-style: italic;
        }
        
        .export-btn {
            background: #28a745;
            color: white;
            border: none;
            padding: 0.5rem 1rem;
            border-radius: 4px;
            cursor: pointer;
            font-size: 0.9rem;
        }
        
        .export-btn:hover { background: #218838; }
        
        @media (max-width: 768px) {
            .summary { grid-template-columns: 1fr; }
            .filters { flex-direction: column; align-items: stretch; }
            .table-container { overflow-x: auto; }
            table { min-width: 800px; }
            .tab-nav { flex-direction: column; }
            .tab-nav button { text-align: left; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 CodeQT Analysis Report</h1>
            <div class="meta">
                Repository: <strong>$repo_name</strong> | 
                Branch: <strong>$branch_name</strong> | 
                Generated: <strong>$(date)</strong>$previous_comparison_text
            </div>
        </div>
        
        <div class="tab-nav">
            <button class="tab-btn active" onclick="switchTab('overview')">📊 Overview</button>
            <button class="tab-btn" onclick="switchTab('issues')">🐛 All Issues</button>
            <button class="tab-btn" onclick="switchTab('trends')" id="trends-tab" style="display: none;">📈 Trends</button>
        </div>
        
        <div class="tab-content">
            <!-- Overview Tab -->
            <div id="overview" class="tab-pane active">
                <div class="summary">
                    <div class="card codeql">
                        <h3>🛡️ CodeQL</h3>
                        <div id="codeql-stats">Loading...</div>
                    </div>
                    <div class="card sonar">
                        <h3>📊 SonarQube</h3>
                        <div id="sonar-stats">Loading...</div>
                    </div>
                    <div class="card combined">
                        <h3>📈 Combined</h3>
                        <div id="combined-stats">Loading...</div>
                    </div>
                </div>
            </div>
            
            <!-- Issues Tab -->
            <div id="issues" class="tab-pane">
                <div class="filters">
                    <div class="filter-group">
                        <label>Search</label>
                        <input type="text" id="search" placeholder="Search files, rules, messages...">
                    </div>
                    <div class="filter-group">
                        <label>Tool</label>
                        <select id="tool-filter">
                            <option value="">All Tools</option>
                            <option value="CodeQL">CodeQL</option>
                            <option value="SonarQube">SonarQube</option>
                        </select>
                    </div>
                    <div class="filter-group">
                        <label>Severity</label>
                        <select id="severity-filter">
                            <option value="">All Severities</option>
                            <option value="CRITICAL">Critical</option>
                            <option value="HIGH">High</option>
                            <option value="MAJOR">Major</option>
                            <option value="MEDIUM">Medium</option>
                            <option value="MINOR">Minor</option>
                            <option value="INFO">Info</option>
                        </select>
                    </div>
                    <div class="filter-group">
                        <label>Type</label>
                        <select id="type-filter">
                            <option value="">All Types</option>
                            <option value="SECURITY">Security</option>
                            <option value="CODE_SMELL">Code Smell</option>
                            <option value="BUG">Bug</option>
                            <option value="VULNERABILITY">Vulnerability</option>
                        </select>
                    </div>
                    <div class="filter-group">
                        <label>&nbsp;</label>
                        <button class="export-btn" onclick="exportCSV()">Export CSV</button>
                    </div>
                </div>
                
                <div class="table-container">
                    <table>
                        <thead>
                            <tr>
                                <th>Tool</th>
                                <th>Severity</th>
                                <th>Type</th>
                                <th>Rule</th>
                                <th>File</th>
                                <th>Line</th>
                                <th>Message</th>
                            </tr>
                        </thead>
                        <tbody id="issues-table">
                            <tr><td colspan="7" class="no-data">Loading issues...</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
            
            <!-- Trends Tab -->
            <div id="trends" class="tab-pane">
                <div class="trend-summary" id="trend-summary">
                    <!-- Trend summary cards will be populated by JavaScript -->
                </div>
                
                <div class="filters">
                    <div class="filter-group">
                        <label>Search</label>
                        <input type="text" id="trend-search" placeholder="Search files, rules, messages...">
                    </div>
                    <div class="filter-group">
                        <label>Change Type</label>
                        <select id="trend-filter">
                            <option value="">All Changes</option>
                            <option value="new">New Issues</option>
                            <option value="resolved">Resolved Issues</option>
                        </select>
                    </div>
                    <div class="filter-group">
                        <label>Tool</label>
                        <select id="trend-tool-filter">
                            <option value="">All Tools</option>
                            <option value="CodeQL">CodeQL</option>
                            <option value="SonarQube">SonarQube</option>
                        </select>
                    </div>
                    <div class="filter-group">
                        <label>&nbsp;</label>
                        <button class="export-btn" onclick="exportTrendCSV()">Export Trends CSV</button>
                    </div>
                </div>
                
                <div class="table-container">
                    <table>
                        <thead>
                            <tr>
                                <th>Change</th>
                                <th>Tool</th>
                                <th>Severity</th>
                                <th>Type</th>
                                <th>Rule</th>
                                <th>File</th>
                                <th>Line</th>
                                <th>Message</th>
                            </tr>
                        </thead>
                        <tbody id="trends-table">
                            <tr><td colspan="8" class="no-data">Loading trend analysis...</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Embedded data
        const CODEQL_DATA = $codeql_data;
        const SONAR_DATA = $sonar_data;
        const PREVIOUS_CODEQL_DATA = $previous_codeql_data;
        const PREVIOUS_SONAR_DATA = $previous_sonar_data;
        const PREVIOUS_TIMESTAMP = '$previous_timestamp';
        
        let allIssues = [];
        let filteredIssues = [];
        let trendData = {
            newIssues: [],
            resolvedIssues: [],
            filteredTrends: []
        };
        
        function init() {
            processData();
            processTrendData();
            renderStats();
            renderTable();
            setupFilters();
            
            // Show trends tab if we have historical data
            if (PREVIOUS_CODEQL_DATA !== null || PREVIOUS_SONAR_DATA !== null) {
                document.getElementById('trends-tab').style.display = 'block';
                renderTrendSummary();
                renderTrendsTable();
                setupTrendFilters();
            }
        }
        
        function switchTab(tabName) {
            // Hide all tab panes
            document.querySelectorAll('.tab-pane').forEach(pane => {
                pane.classList.remove('active');
            });
            
            // Remove active class from all tab buttons
            document.querySelectorAll('.tab-btn').forEach(btn => {
                btn.classList.remove('active');
            });
            
            // Show selected tab pane
            document.getElementById(tabName).classList.add('active');
            
            // Add active class to clicked button
            event.target.classList.add('active');
        }
        
        function processData() {
            allIssues = [];
            
            // Process CodeQL issues
            if (CODEQL_DATA && CODEQL_DATA.issues) {
                CODEQL_DATA.issues.forEach(issue => {
                    allIssues.push({
                        tool: 'CodeQL',
                        severity: issue.severity || 'INFO',
                        type: issue.category || 'SECURITY',
                        rule: issue.ruleId || 'unknown',
                        file: cleanFilePath(issue.component || 'unknown'),
                        line: issue.line || 0,
                        message: issue.message || '',
                        effort: issue.effort || '5min',
                        key: generateIssueKey('CodeQL', issue)
                    });
                });
            }
            
            // Process SonarQube issues
            if (SONAR_DATA && SONAR_DATA.issues) {
                SONAR_DATA.issues.forEach(issue => {
                    allIssues.push({
                        tool: 'SonarQube',
                        severity: issue.severity || 'INFO',
                        type: issue.type || 'CODE_SMELL',
                        rule: issue.rule || 'unknown',
                        file: cleanFilePath(issue.component || 'unknown'),
                        line: issue.line || 0,
                        message: issue.message || '',
                        effort: issue.effort || issue.debt || '5min',
                        key: generateIssueKey('SonarQube', issue)
                    });
                });
            }
            
            filteredIssues = [...allIssues];
        }
        
        function processTrendData() {
            if (!PREVIOUS_CODEQL_DATA && !PREVIOUS_SONAR_DATA) {
                return;
            }
            
            // Process previous issues
            let previousIssues = [];
            
            if (PREVIOUS_CODEQL_DATA && PREVIOUS_CODEQL_DATA.issues) {
                PREVIOUS_CODEQL_DATA.issues.forEach(issue => {
                    previousIssues.push({
                        tool: 'CodeQL',
                        severity: issue.severity || 'INFO',
                        type: issue.category || 'SECURITY',
                        rule: issue.ruleId || 'unknown',
                        file: cleanFilePath(issue.component || 'unknown'),
                        line: issue.line || 0,
                        message: issue.message || '',
                        effort: issue.effort || '5min',
                        key: generateIssueKey('CodeQL', issue)
                    });
                });
            }
            
            if (PREVIOUS_SONAR_DATA && PREVIOUS_SONAR_DATA.issues) {
                PREVIOUS_SONAR_DATA.issues.forEach(issue => {
                    previousIssues.push({
                        tool: 'SonarQube',
                        severity: issue.severity || 'INFO',
                        type: issue.type || 'CODE_SMELL',
                        rule: issue.rule || 'unknown',
                        file: cleanFilePath(issue.component || 'unknown'),
                        line: issue.line || 0,
                        message: issue.message || '',
                        effort: issue.effort || issue.debt || '5min',
                        key: generateIssueKey('SonarQube', issue)
                    });
                });
            }
            
            // Find new issues (present in current but not in previous)
            const previousKeys = new Set(previousIssues.map(issue => issue.key));
            trendData.newIssues = allIssues.filter(issue => !previousKeys.has(issue.key))
                .map(issue => ({...issue, trend: 'new'}));
            
            // Find resolved issues (present in previous but not in current)
            const currentKeys = new Set(allIssues.map(issue => issue.key));
            trendData.resolvedIssues = previousIssues.filter(issue => !currentKeys.has(issue.key))
                .map(issue => ({...issue, trend: 'resolved'}));
            
            trendData.filteredTrends = [...trendData.newIssues, ...trendData.resolvedIssues];
        }
        
        function generateIssueKey(tool, issue) {
            // Generate a unique key for each issue to track changes
            if (tool === 'CodeQL') {
                return \`\${tool}-\${issue.ruleId || 'unknown'}-\${cleanFilePath(issue.component || 'unknown')}-\${issue.line || 0}\`;
            } else {
                return \`\${tool}-\${issue.rule || 'unknown'}-\${cleanFilePath(issue.component || 'unknown')}-\${issue.line || 0}\`;
            }
        }
        
        function cleanFilePath(component) {
            // Remove project prefix from SonarQube paths
            if (component.includes(':')) {
                return component.split(':')[1] || component;
            }
            return component;
        }
        
        function renderStats() {
            const codeqlIssues = allIssues.filter(i => i.tool === 'CodeQL');
            const sonarIssues = allIssues.filter(i => i.tool === 'SonarQube');
            
            // CodeQL stats
            const codeqlStats = document.getElementById('codeql-stats');
            const codeqlTotal = codeqlIssues.length;
            const codeqlSecurity = codeqlIssues.filter(i => i.type === 'SECURITY').length;
            
            codeqlStats.innerHTML = \`
                <div class="stat">
                    <span>Total Issues</span>
                    <span class="stat-value info">\${codeqlTotal}</span>
                </div>
                <div class="stat">
                    <span>Security Issues</span>
                    <span class="stat-value high">\${codeqlSecurity}</span>
                </div>
            \`;
            
            // SonarQube stats
            const sonarStats = document.getElementById('sonar-stats');
            const sonarTotal = sonarIssues.length;
            const sonarBugs = sonarIssues.filter(i => i.type === 'BUG').length;
            const sonarVulns = sonarIssues.filter(i => i.type === 'VULNERABILITY').length;
            
            sonarStats.innerHTML = \`
                <div class="stat">
                    <span>Total Issues</span>
                    <span class="stat-value info">\${sonarTotal}</span>
                </div>
                <div class="stat">
                    <span>Bugs</span>
                    <span class="stat-value critical">\${sonarBugs}</span>
                </div>
                <div class="stat">
                    <span>Vulnerabilities</span>
                    <span class="stat-value high">\${sonarVulns}</span>
                </div>
            \`;
            
            // Combined stats
            const combinedStats = document.getElementById('combined-stats');
            const totalIssues = allIssues.length;
            const securityTotal = allIssues.filter(i => 
                i.type === 'SECURITY' || i.type === 'VULNERABILITY').length;
            const criticalHigh = allIssues.filter(i => 
                i.severity === 'CRITICAL' || i.severity === 'HIGH' || i.severity === 'MAJOR').length;
            
            combinedStats.innerHTML = \`
                <div class="stat">
                    <span>Total Issues</span>
                    <span class="stat-value info">\${totalIssues}</span>
                </div>
                <div class="stat">
                    <span>Security Related</span>
                    <span class="stat-value high">\${securityTotal}</span>
                </div>
                <div class="stat">
                    <span>Critical/High/Major</span>
                    <span class="stat-value critical">\${criticalHigh}</span>
                </div>
            \`;
        }
        
        function renderTrendSummary() {
            const trendSummary = document.getElementById('trend-summary');
            const newCount = trendData.newIssues.length;
            const resolvedCount = trendData.resolvedIssues.length;
            const netChange = newCount - resolvedCount;
            
            const previousDate = PREVIOUS_TIMESTAMP ? new Date(parseInt(PREVIOUS_TIMESTAMP) * 1000).toLocaleDateString() : 'Unknown';
            
            trendSummary.innerHTML = \`
                <div class="trend-chart">
                    <h4>🆕 New Issues</h4>
                    <div class="trend-number positive">+\${newCount}</div>
                    <small>Since \${previousDate}</small>
                </div>
                <div class="trend-chart">
                    <h4>✅ Resolved Issues</h4>
                    <div class="trend-number negative">-\${resolvedCount}</div>
                    <small>Since \${previousDate}</small>
                </div>
                <div class="trend-chart">
                    <h4>📊 Net Change</h4>
                    <div class="trend-number \${netChange > 0 ? 'positive' : netChange < 0 ? 'negative' : 'neutral'}">
                        \${netChange > 0 ? '+' : ''}\${netChange}
                    </div>
                    <small>\${netChange > 0 ? 'More issues' : netChange < 0 ? 'Fewer issues' : 'No change'}</small>
                </div>
                <div class="trend-chart">
                    <h4>🔄 Change Rate</h4>
                    <div class="trend-number neutral">\${((newCount + resolvedCount) / Math.max(allIssues.length, 1) * 100).toFixed(1)}%</div>
                    <small>Issues changed</small>
                </div>
            \`;
        }
        
        function renderTable() {
            const tbody = document.getElementById('issues-table');
            
            if (filteredIssues.length === 0) {
                tbody.innerHTML = '<tr><td colspan="7" class="no-data">No issues match current filters</td></tr>';
                return;
            }
            
            tbody.innerHTML = filteredIssues.map(issue => \`
                <tr>
                    <td><span class="tool-badge">\${issue.tool}</span></td>
                    <td><span class="severity-badge \${getSeverityClass(issue.severity)}">\${issue.severity}</span></td>
                    <td>\${issue.type}</td>
                    <td><code class="rule-code">\${issue.rule}</code></td>
                    <td><div class="file-path">\${getFileName(issue.file)}</div></td>
                    <td><span class="line-num">\${issue.line || '-'}</span></td>
                    <td><div class="message">\${issue.message}</div></td>
                </tr>
            \`).join('');
        }
        
        function renderTrendsTable() {
            const tbody = document.getElementById('trends-table');
            
            if (trendData.filteredTrends.length === 0) {
                tbody.innerHTML = '<tr><td colspan="8" class="no-data">No trend data available</td></tr>';
                return;
            }
            
            tbody.innerHTML = trendData.filteredTrends.map(issue => \`
                <tr>
                    <td><span class="trend-badge \${issue.trend}">\${issue.trend.toUpperCase()}</span></td>
                    <td><span class="tool-badge">\${issue.tool}</span></td>
                    <td><span class="severity-badge \${getSeverityClass(issue.severity)}">\${issue.severity}</span></td>
                    <td>\${issue.type}</td>
                    <td><code class="rule-code">\${issue.rule}</code></td>
                    <td><div class="file-path">\${getFileName(issue.file)}</div></td>
                    <td><span class="line-num">\${issue.line || '-'}</span></td>
                    <td><div class="message">\${issue.message}</div></td>
                </tr>
            \`).join('');
        }
        
        function getSeverityClass(severity) {
            const map = {
                'CRITICAL': 'critical',
                'HIGH': 'high',
                'MAJOR': 'high',
                'MEDIUM': 'medium',
                'MINOR': 'low',
                'INFO': 'info'
            };
            return map[severity] || 'info';
        }
        
        function getFileName(filePath) {
            return filePath || 'unknown';
        }
        
        function setupFilters() {
            document.getElementById('search').addEventListener('input', applyFilters);
            document.getElementById('tool-filter').addEventListener('change', applyFilters);
            document.getElementById('severity-filter').addEventListener('change', applyFilters);
            document.getElementById('type-filter').addEventListener('change', applyFilters);
        }
        
        function setupTrendFilters() {
            document.getElementById('trend-search').addEventListener('input', applyTrendFilters);
            document.getElementById('trend-filter').addEventListener('change', applyTrendFilters);
            document.getElementById('trend-tool-filter').addEventListener('change', applyTrendFilters);
        }
        
        function applyFilters() {
            const search = document.getElementById('search').value.toLowerCase();
            const tool = document.getElementById('tool-filter').value;
            const severity = document.getElementById('severity-filter').value;
            const type = document.getElementById('type-filter').value;
            
            filteredIssues = allIssues.filter(issue => {
                const matchesSearch = !search || 
                    issue.file.toLowerCase().includes(search) ||
                    issue.rule.toLowerCase().includes(search) ||
                    issue.message.toLowerCase().includes(search);
                
                const matchesTool = !tool || issue.tool === tool;
                const matchesSeverity = !severity || issue.severity === severity;
                const matchesType = !type || issue.type === type;
                
                return matchesSearch && matchesTool && matchesSeverity && matchesType;
            });
            
            renderTable();
        }
        
        function applyTrendFilters() {
            const search = document.getElementById('trend-search').value.toLowerCase();
            const trendType = document.getElementById('trend-filter').value;
            const tool = document.getElementById('trend-tool-filter').value;
            
            const allTrends = [...trendData.newIssues, ...trendData.resolvedIssues];
            
            trendData.filteredTrends = allTrends.filter(issue => {
                const matchesSearch = !search || 
                    issue.file.toLowerCase().includes(search) ||
                    issue.rule.toLowerCase().includes(search) ||
                    issue.message.toLowerCase().includes(search);
                
                const matchesTrend = !trendType || issue.trend === trendType;
                const matchesTool = !tool || issue.tool === tool;
                
                return matchesSearch && matchesTrend && matchesTool;
            });
            
            renderTrendsTable();
        }
        
        function exportCSV() {
            const headers = ['Tool', 'Severity', 'Type', 'Rule', 'File', 'Line', 'Message'];
            const csvContent = [
                headers.join(','),
                ...filteredIssues.map(issue => [
                    issue.tool,
                    issue.severity,
                    issue.type,
                    \`"\${issue.rule}"\`,
                    \`"\${issue.file}"\`,
                    issue.line,
                    \`"\${issue.message.replace(/"/g, '""')}"\`
                ].join(','))
            ].join('\\n');
            
            const blob = new Blob([csvContent], { type: 'text/csv' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = \`codeqt-report-\${new Date().toISOString().split('T')[0]}.csv\`;
            a.click();
            URL.revokeObjectURL(url);
        }
        
        function exportTrendCSV() {
            const headers = ['Change', 'Tool', 'Severity', 'Type', 'Rule', 'File', 'Line', 'Message'];
            const csvContent = [
                headers.join(','),
                ...trendData.filteredTrends.map(issue => [
                    issue.trend.toUpperCase(),
                    issue.tool,
                    issue.severity,
                    issue.type,
                    \`"\${issue.rule}"\`,
                    \`"\${issue.file}"\`,
                    issue.line,
                    \`"\${issue.message.replace(/"/g, '""')}"\`
                ].join(','))
            ].join('\\n');
            
            const blob = new Blob([csvContent], { type: 'text/csv' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = \`codeqt-trends-\${new Date().toISOString().split('T')[0]}.csv\`;
            a.click();
            URL.revokeObjectURL(url);
        }
        
        // Initialize on page load
        document.addEventListener('DOMContentLoaded', init);
    </script>
</body>
</html>
EOF
    
    echo "✅ Enhanced HTML report with trend analysis generated: $output_file"
    return 0
}

# Export function for use in other scripts
export -f generate_html_report