#!/bin/bash
# generate-html-report.sh - Generate minimal HTML report from CodeQT results

generate_html_report() {
    local results_dir="$1"
    local repo_name="$2"
    local branch_name="$3"
    local timestamp="$4"
    
    local codeql_file="$results_dir/codeql/results.json"
    local sonar_file="$results_dir/sonar/results.json"
    local output_file="$results_dir/combined-report.html"
    
    echo "🔧 Generating HTML report for $repo_name..."
    
    # Check if at least one results file exists
    if [ ! -f "$codeql_file" ] && [ ! -f "$sonar_file" ]; then
        echo "⚠️  No results files found. Skipping HTML report generation."
        return 1
    fi
    
    # Read JSON data safely
    local codeql_data="null"
    local sonar_data="null"
    
    if [ -f "$codeql_file" ]; then
        echo "📊 Including CodeQL data..."
        codeql_data=$(cat "$codeql_file" | jq -c .)
    fi
    
    if [ -f "$sonar_file" ]; then
        echo "📊 Including SonarQube data..."
        sonar_data=$(cat "$sonar_file" | jq -c .)
    fi
    
    # Create the minimal HTML report
    cat > "$output_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CodeQT Report - REPO_PLACEHOLDER</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            line-height: 1.6;
            color: #333;
            background: #f8f9fa;
            padding: 20px;
        }
        
        .container { max-width: 1200px; margin: 0 auto; }
        
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
        
        .card h3 { margin-bottom: 1rem; color: #495057; }
        .stat { display: flex; justify-content: space-between; margin: 0.5rem 0; }
        .stat-value { font-weight: bold; padding: 0.25rem 0.5rem; border-radius: 4px; }
        
        .critical { background: #f8d7da; color: #721c24; }
        .high { background: #fff3cd; color: #856404; }
        .medium { background: #d1ecf1; color: #0c5460; }
        .low { background: #d4edda; color: #155724; }
        .info { background: #e2e3e5; color: #383d41; }
        
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
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 CodeQT Analysis Report</h1>
            <div class="meta">
                Repository: <strong>REPO_PLACEHOLDER</strong> | 
                Branch: <strong>BRANCH_PLACEHOLDER</strong> | 
                Generated: <strong>DATE_PLACEHOLDER</strong>
            </div>
        </div>
        
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
    
    <script>
        // Embedded data will be injected here
        const CODEQL_DATA = CODEQL_PLACEHOLDER;
        const SONAR_DATA = SONAR_PLACEHOLDER;
        
        let allIssues = [];
        let filteredIssues = [];
        
        function init() {
            processData();
            renderStats();
            renderTable();
            setupFilters();
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
                        effort: issue.effort || '5min'
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
                        effort: issue.effort || issue.debt || '5min'
                    });
                });
            }
            
            filteredIssues = [...allIssues];
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
            
            codeqlStats.innerHTML = `
                <div class="stat">
                    <span>Total Issues</span>
                    <span class="stat-value info">${codeqlTotal}</span>
                </div>
                <div class="stat">
                    <span>Security Issues</span>
                    <span class="stat-value high">${codeqlSecurity}</span>
                </div>
            `;
            
            // SonarQube stats
            const sonarStats = document.getElementById('sonar-stats');
            const sonarTotal = sonarIssues.length;
            const sonarBugs = sonarIssues.filter(i => i.type === 'BUG').length;
            const sonarVulns = sonarIssues.filter(i => i.type === 'VULNERABILITY').length;
            
            sonarStats.innerHTML = `
                <div class="stat">
                    <span>Total Issues</span>
                    <span class="stat-value info">${sonarTotal}</span>
                </div>
                <div class="stat">
                    <span>Bugs</span>
                    <span class="stat-value critical">${sonarBugs}</span>
                </div>
                <div class="stat">
                    <span>Vulnerabilities</span>
                    <span class="stat-value high">${sonarVulns}</span>
                </div>
            `;
            
            // Combined stats
            const combinedStats = document.getElementById('combined-stats');
            const totalIssues = allIssues.length;
            const securityTotal = allIssues.filter(i => 
                i.type === 'SECURITY' || i.type === 'VULNERABILITY').length;
            const criticalHigh = allIssues.filter(i => 
                i.severity === 'CRITICAL' || i.severity === 'HIGH' || i.severity === 'MAJOR').length;
            
            combinedStats.innerHTML = `
                <div class="stat">
                    <span>Total Issues</span>
                    <span class="stat-value info">${totalIssues}</span>
                </div>
                <div class="stat">
                    <span>Security Related</span>
                    <span class="stat-value high">${securityTotal}</span>
                </div>
                <div class="stat">
                    <span>Critical/High/Major</span>
                    <span class="stat-value critical">${criticalHigh}</span>
                </div>
            `;
        }
        
        function renderTable() {
            const tbody = document.getElementById('issues-table');
            
            if (filteredIssues.length === 0) {
                tbody.innerHTML = '<tr><td colspan="7" class="no-data">No issues match current filters</td></tr>';
                return;
            }
            
            tbody.innerHTML = filteredIssues.map(issue => `
                <tr>
                    <td><span class="tool-badge">${issue.tool}</span></td>
                    <td><span class="severity-badge ${getSeverityClass(issue.severity)}">${issue.severity}</span></td>
                    <td>${issue.type}</td>
                    <td><code class="rule-code">${issue.rule}</code></td>
                    <td><div class="file-path">${getFileName(issue.file)}</div></td>
                    <td><span class="line-num">${issue.line || '-'}</span></td>
                    <td><div class="message">${issue.message}</div></td>
                </tr>
            `).join('');
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
            // Return the full file path instead of just the filename
            return filePath || 'unknown';
        }
        
        function setupFilters() {
            document.getElementById('search').addEventListener('input', applyFilters);
            document.getElementById('tool-filter').addEventListener('change', applyFilters);
            document.getElementById('severity-filter').addEventListener('change', applyFilters);
            document.getElementById('type-filter').addEventListener('change', applyFilters);
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
        
        function exportCSV() {
            const headers = ['Tool', 'Severity', 'Type', 'Rule', 'File', 'Line', 'Message'];
            const csvContent = [
                headers.join(','),
                ...filteredIssues.map(issue => [
                    issue.tool,
                    issue.severity,
                    issue.type,
                    `"${issue.rule}"`,
                    `"${issue.file}"`,
                    issue.line,
                    `"${issue.message.replace(/"/g, '""')}"`
                ].join(','))
            ].join('\\n');
            
            const blob = new Blob([csvContent], { type: 'text/csv' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `codeqt-report-${new Date().toISOString().split('T')[0]}.csv`;
            a.click();
            URL.revokeObjectURL(url);
        }
        
        // Initialize on page load
        document.addEventListener('DOMContentLoaded', init);
    </script>
</body>
</html>
EOF

    # Replace placeholders (using | as delimiter to handle / in branch names)
    sed -i.bak "s|REPO_PLACEHOLDER|$repo_name|g" "$output_file"
    sed -i.bak "s|BRANCH_PLACEHOLDER|$branch_name|g" "$output_file"
    sed -i.bak "s|DATE_PLACEHOLDER|$(date)|g" "$output_file"
    
    # Inject JSON data (escape for JavaScript)
    if [ "$codeql_data" != "null" ]; then
        # Use a temporary file to avoid sed issues with large JSON
        echo "const CODEQL_DATA = $codeql_data;" > /tmp/codeql_data.js
        sed -i.bak '/CODEQL_PLACEHOLDER/r /tmp/codeql_data.js' "$output_file"
        sed -i.bak 's/const CODEQL_DATA = CODEQL_PLACEHOLDER;//g' "$output_file"
        rm -f /tmp/codeql_data.js
    else
        sed -i.bak "s/CODEQL_PLACEHOLDER/null/g" "$output_file"
    fi
    
    if [ "$sonar_data" != "null" ]; then
        echo "const SONAR_DATA = $sonar_data;" > /tmp/sonar_data.js
        sed -i.bak '/SONAR_PLACEHOLDER/r /tmp/sonar_data.js' "$output_file"
        sed -i.bak 's/const SONAR_DATA = SONAR_PLACEHOLDER;//g' "$output_file"
        rm -f /tmp/sonar_data.js
    else
        sed -i.bak "s/SONAR_PLACEHOLDER/null/g" "$output_file"
    fi
    
    # Clean up backup files
    rm -f "$output_file.bak"
    
    echo "✅ HTML report generated: $output_file"
    return 0
}

# Export function for use in other scripts
export -f generate_html_report
