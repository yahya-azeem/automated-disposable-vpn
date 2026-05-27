<script lang="ts">
  import { onMount } from 'svelte';
  import JSZip from 'jszip';

  // Config State
  let githubToken = '';
  let githubRepo = 'yahya-azeem/automated-disposable-vpn';
  let ddnsHostname = 'amass.hopto.org';
  let ddnsUsername = 'yahyaazeem44@gmail.com';
  let ddnsPassword = 'Brobrobro1';

  // UI State
  let activeTab = 'control'; // 'control' | 'settings'
  let currentAction = 'idle'; // 'idle' | 'deploying' | 'destroying'
  let workflowStatus = 'Idle';
  let progressPercent = 0;
  let clientYaml = '';
  let serverCert = '';
  let errorMessage = '';
  let successMessage = '';
  let activeRegion = '';
  let activeZone = '';

  // Polling variables
  let pollIntervalId: number | null = null;
  let progressIntervalId: number | null = null;
  let currentRunId: number | null = null;

  // Load configuration on mount
  onMount(() => {
    githubToken = localStorage.getItem('tt_github_token') || '';
    githubRepo = localStorage.getItem('tt_github_repo') || 'yahya-azeem/automated-disposable-vpn';
    ddnsHostname = localStorage.getItem('tt_ddns_hostname') || 'amass.hopto.org';
    ddnsUsername = localStorage.getItem('tt_ddns_username') || 'yahyaazeem44@gmail.com';
    ddnsPassword = localStorage.getItem('tt_ddns_password') || 'Brobrobro1';
  });

  // Save config
  function saveSettings() {
    localStorage.setItem('tt_github_token', githubToken);
    localStorage.setItem('tt_github_repo', githubRepo);
    localStorage.setItem('tt_ddns_hostname', ddnsHostname);
    localStorage.setItem('tt_ddns_username', ddnsUsername);
    localStorage.setItem('tt_ddns_password', ddnsPassword);
    
    successMessage = 'Settings saved successfully!';
    setTimeout(() => { successMessage = ''; }, 3000);
  }

  // Clear messages
  function resetMessages() {
    errorMessage = '';
    successMessage = '';
  }

  // Interpolate progress smoothly during runs
  function startProgressSimulation(durationSeconds: number) {
    if (progressIntervalId) clearInterval(progressIntervalId);
    progressPercent = 5;
    
    const intervalMs = 1000;
    const increment = 90 / durationSeconds; // Smoothly build to 95%

    progressIntervalId = window.setInterval(() => {
      if (progressPercent < 95) {
        progressPercent = Math.min(95, progressPercent + increment);
      }
    }, intervalMs);
  }

  function stopProgressSimulation(isSuccess: boolean) {
    if (progressIntervalId) {
      clearInterval(progressIntervalId);
      progressIntervalId = null;
    }
    progressPercent = isSuccess ? 100 : 0;
  }

  // Poll workflow status
  async function pollWorkflowRun(runId: number, isDeploy: boolean) {
    if (pollIntervalId) clearInterval(pollIntervalId);

    const headers = {
      'Authorization': `Bearer ${githubToken}`,
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28'
    };

    pollIntervalId = window.setInterval(async () => {
      try {
        const res = await fetch(`https://api.github.com/repos/${githubRepo}/actions/runs/${runId}`, { headers });
        if (!res.ok) throw new Error(`Failed to fetch run status: ${res.statusText}`);
        
        const run = await res.json();
        workflowStatus = run.status.replace(/_/g, ' ').toUpperCase();

        if (run.status === 'completed') {
          clearInterval(pollIntervalId!);
          pollIntervalId = null;
          stopProgressSimulation(run.conclusion === 'success');

          if (run.conclusion === 'success') {
            if (isDeploy) {
              workflowStatus = 'EXTRACTING PROFILE...';
              await downloadAndExtractArtifact(runId);
            } else {
              workflowStatus = 'DESTROY COMPLETED';
              successMessage = 'VPN Infrastructure successfully destroyed!';
              currentAction = 'idle';
            }
          } else {
            workflowStatus = 'FAILED';
            errorMessage = `Workflow run failed with conclusion: ${run.conclusion}`;
            currentAction = 'idle';
          }
        }
      } catch (err: any) {
        console.error(err);
        errorMessage = err.message;
        clearInterval(pollIntervalId!);
        pollIntervalId = null;
        stopProgressSimulation(false);
        currentAction = 'idle';
      }
    }, 4000);
  }

  // Find latest started run ID
  async function findNewRunId(workflowFileName: string, triggerTime: Date): Promise<number> {
    const headers = {
      'Authorization': `Bearer ${githubToken}`,
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28'
    };

    for (let attempt = 1; attempt <= 10; attempt++) {
      await new Promise(r => setTimeout(r, 4000));
      try {
        const res = await fetch(`https://api.github.com/repos/${githubRepo}/actions/workflows/${workflowFileName}/runs?per_page=3`, { headers });
        if (!res.ok) continue;

        const data = await res.json();
        const runs = data.workflow_runs || [];

        for (const run of runs) {
          const runCreatedAt = new Date(run.created_at);
          // Confirm this run was created *after* we triggered it
          if (runCreatedAt.getTime() > triggerTime.getTime() - 10000) {
            return run.id;
          }
        }
      } catch (e) {
        console.error('Error finding run ID:', e);
      }
    }
    throw new Error('Timeout waiting for GitHub Actions workflow to start.');
  }

  // Download & Extract ZIP Artifact
  async function downloadAndExtractArtifact(runId: number) {
    const headers = {
      'Authorization': `Bearer ${githubToken}`,
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28'
    };

    try {
      // 1. Fetch artifacts metadata
      const res = await fetch(`https://api.github.com/repos/${githubRepo}/actions/runs/${runId}/artifacts`, { headers });
      if (!res.ok) throw new Error('Failed to retrieve run artifacts metadata.');
      
      const data = await res.json();
      const artifacts = data.artifacts || [];
      const configArtifact = artifacts.find((a: any) => a.name === 'TrustTunnel-Client-Config');

      if (!configArtifact) {
        throw new Error('Client config artifact not found. The server may have failed to export config.');
      }

      // 2. Download ZIP file
      workflowStatus = 'DOWNLOADING PROFILE ZIP...';
      const downloadRes = await fetch(`https://api.github.com/repos/${githubRepo}/actions/artifacts/${configArtifact.id}/zip`, { headers });
      if (!downloadRes.ok) throw new Error('Failed to download artifact zip.');

      const arrayBuffer = await downloadRes.arrayBuffer();

      // 3. Extract client.yaml using JSZip
      workflowStatus = 'UNZIPPING CLIENT CONFIG...';
      const zip = await JSZip.loadAsync(arrayBuffer);
      const yamlFile = zip.file('client.yaml');

      if (!yamlFile) {
        throw new Error('client.yaml not found inside the downloaded archive.');
      }

      clientYaml = await yamlFile.async('string');
      
      // Extract Certificate
      const certMatch = clientYaml.match(/certificate\s*=\s*"""([\s\S]*?)"""/);
      if (certMatch && certMatch[1]) {
        serverCert = certMatch[1].trim();
      }

      workflowStatus = 'COMPLETED';
      successMessage = 'VPN successfully deployed & config retrieved!';
      currentAction = 'idle';
    } catch (err: any) {
      console.error(err);
      errorMessage = err.message;
      workflowStatus = 'FAILED';
      currentAction = 'idle';
    }
  }

  // Trigger Deployment
  async function triggerDeployment(region: string, zone: string) {
    if (!githubToken) {
      errorMessage = 'Please set your GitHub Personal Access Token in Settings first.';
      return;
    }
    
    resetMessages();
    currentAction = 'deploying';
    workflowStatus = 'TRIGGERING DEPLOYMENT...';
    activeRegion = region;
    activeZone = zone;
    clientYaml = '';
    serverCert = '';
    
    const triggerTime = new Date();
    startProgressSimulation(160); // GHA run takes ~2.5 mins (150-160s)

    try {
      const res = await fetch(`https://api.github.com/repos/${githubRepo}/actions/workflows/deploy-gcp.yml/dispatches`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${githubToken}`,
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          ref: 'main',
          inputs: {
            region,
            zone,
            ddns_hostname: ddnsHostname,
            ddns_username: ddnsUsername,
            ddns_password: ddnsPassword
          }
        })
      });

      if (!res.ok) {
        const errorText = await res.text();
        throw new Error(`Dispatch failed: ${res.statusText}. ${errorText}`);
      }

      workflowStatus = 'FINDING WORKFLOW RUN...';
      const runId = await findNewRunId('deploy-gcp.yml', triggerTime);
      currentRunId = runId;
      
      workflowStatus = 'QUEUED';
      pollWorkflowRun(runId, true);
    } catch (err: any) {
      console.error(err);
      errorMessage = err.message;
      stopProgressSimulation(false);
      currentAction = 'idle';
      workflowStatus = 'IDLE';
    }
  }

  // Trigger Destroy
  async function triggerDestroy() {
    if (!githubToken) {
      errorMessage = 'Please set your GitHub Personal Access Token in Settings first.';
      return;
    }

    if (!confirm('Are you sure you want to completely destroy the active GCE VPN instance?')) {
      return;
    }

    resetMessages();
    currentAction = 'destroying';
    workflowStatus = 'TRIGGERING TEARDOWN...';
    
    const triggerTime = new Date();
    startProgressSimulation(60); // Destruction takes ~1 min

    try {
      const res = await fetch(`https://api.github.com/repos/${githubRepo}/actions/workflows/destroy-gcp.yml/dispatches`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${githubToken}`,
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          ref: 'main'
        })
      });

      if (!res.ok) {
        const errorText = await res.text();
        throw new Error(`Teardown dispatch failed: ${res.statusText}. ${errorText}`);
      }

      workflowStatus = 'FINDING WORKFLOW RUN...';
      const runId = await findNewRunId('destroy-gcp.yml', triggerTime);
      currentRunId = runId;

      workflowStatus = 'QUEUED';
      pollWorkflowRun(runId, false);
    } catch (err: any) {
      console.error(err);
      errorMessage = err.message;
      stopProgressSimulation(false);
      currentAction = 'idle';
      workflowStatus = 'IDLE';
    }
  }

  // Copy to clipboard
  let copiedYaml = false;
  let copiedCert = false;

  async function copyToClipboard(text: string, type: 'yaml' | 'cert') {
    try {
      await navigator.clipboard.writeText(text);
      if (type === 'yaml') {
        copiedYaml = true;
        setTimeout(() => copiedYaml = false, 2000);
      } else {
        copiedCert = true;
        setTimeout(() => copiedCert = false, 2000);
      }
    } catch (e) {
      alert('Failed to copy to clipboard.');
    }
  }

  // Download client files locally from browser
  function downloadTextFile(filename: string, text: string) {
    const element = document.createElement('a');
    element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text));
    element.setAttribute('download', filename);
    element.style.display = 'none';
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
  }
</script>

<main class="dashboard-root">
  <div class="glass-container">
    <header class="dashboard-header">
      <div class="logo-area">
        <div class="glow-sphere"></div>
        <h1>TrustTunnel <span>Control Plane</span></h1>
      </div>
      
      <nav class="tab-navigation">
        <button 
          class="tab-btn {activeTab === 'control' ? 'active' : ''}" 
          on:click={() => activeTab = 'control'}
        >
          Control Panel
        </button>
        <button 
          class="tab-btn {activeTab === 'settings' ? 'active' : ''}" 
          on:click={() => activeTab = 'settings'}
        >
          Settings
        </button>
      </nav>
    </header>

    {#if errorMessage}
      <div class="alert-box error-alert">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
        <span>{errorMessage}</span>
      </div>
    {/if}

    {#if successMessage}
      <div class="alert-box success-alert">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
        <span>{successMessage}</span>
      </div>
    {/if}

    {#if activeTab === 'control'}
      <!-- Main Control Area -->
      <section class="control-panel-grid">
        
        <!-- Left Column: Operations -->
        <div class="panel-card region-card">
          <h2>Region Deployment (Always Free)</h2>
          <p class="subtitle">Deploy a disposable node in a GCP Always Free Tier region</p>
          
          <div class="button-list">
            <button 
              class="deploy-btn iowa"
              disabled={currentAction !== 'idle'} 
              on:click={() => triggerDeployment('us-central1', 'us-central1-a')}
            >
              <div class="btn-content">
                <span class="region-title">US Central (Iowa)</span>
                <span class="region-code">us-central1-a</span>
              </div>
              <span class="badge">FREE</span>
            </button>

            <button 
              class="deploy-btn carolina"
              disabled={currentAction !== 'idle'} 
              on:click={() => triggerDeployment('us-east1', 'us-east1-b')}
            >
              <div class="btn-content">
                <span class="region-title">US East (S. Carolina)</span>
                <span class="region-code">us-east1-b</span>
              </div>
              <span class="badge">FREE</span>
            </button>

            <button 
              class="deploy-btn oregon"
              disabled={currentAction !== 'idle'} 
              on:click={() => triggerDeployment('us-west1', 'us-west1-b')}
            >
              <div class="btn-content">
                <span class="region-title">US West (Oregon)</span>
                <span class="region-code">us-west1-b</span>
              </div>
              <span class="badge">FREE</span>
            </button>
          </div>

          <div class="danger-zone">
            <h3>Danger Zone</h3>
            <button 
              class="destroy-btn" 
              disabled={currentAction !== 'idle'} 
              on:click={triggerDestroy}
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>
              Teardown Active VPN Node
            </button>
          </div>
        </div>

        <!-- Right Column: Status & Output -->
        <div class="panel-card status-card">
          <h2>Deployment Status</h2>
          
          <div class="status-indicator-block">
            <div class="status-info">
              <span class="label">Current Status:</span>
              <span class="value-badge status-{workflowStatus.toLowerCase().replace(/ /g, '-')}">
                {workflowStatus}
              </span>
            </div>
            
            {#if currentAction !== 'idle'}
              <div class="progress-bar-container">
                <div class="progress-bar-fill" style="width: {progressPercent}%"></div>
              </div>
              <div class="progress-details">
                <span>Deploying to {activeRegion} ({activeZone})</span>
                <span>{Math.round(progressPercent)}%</span>
              </div>
              
              <div class="status-pulse-spinner">
                <div class="double-bounce1"></div>
                <div class="double-bounce2"></div>
              </div>
            {/if}
          </div>

          {#if clientYaml}
            <div class="output-block-header">
              <h2>Generated VPN Client Configuration</h2>
              <div class="actions">
                <button 
                  class="action-icon-btn" 
                  on:click={() => copyToClipboard(clientYaml, 'yaml')}
                  title="Copy to Clipboard"
                >
                  {copiedYaml ? 'Copied!' : 'Copy'}
                </button>
                <button 
                  class="action-icon-btn" 
                  on:click={() => downloadTextFile('client.yaml', clientYaml)}
                  title="Download File"
                >
                  Download YAML
                </button>
              </div>
            </div>
            <pre class="code-output"><code>{clientYaml}</code></pre>

            {#if serverCert}
              <div class="output-block-header cert-header">
                <h2>Server TLS Certificate (PEM)</h2>
                <div class="actions">
                  <button 
                    class="action-icon-btn" 
                    on:click={() => copyToClipboard(serverCert, 'cert')}
                    title="Copy Certificate"
                  >
                    {copiedCert ? 'Copied!' : 'Copy'}
                  </button>
                  <button 
                    class="action-icon-btn" 
                    on:click={() => downloadTextFile('server.crt', serverCert)}
                    title="Download Certificate File"
                  >
                    Download CRT
                  </button>
                </div>
              </div>
              <pre class="code-output cert-code"><code>{serverCert}</code></pre>
            {/if}
          {:else if currentAction === 'idle'}
            <div class="empty-state">
              <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
              <h3>No Active Profile Displayed</h3>
              <p>Trigger a region deployment to dynamically generate, fetch, and display the client configuration here.</p>
            </div>
          {/if}
        </div>
      </section>

    {:else if activeTab === 'settings'}
      <!-- Configuration Area -->
      <section class="panel-card settings-card">
        <h2>Control Plane Configuration</h2>
        <p class="subtitle">Set your secure credentials. These are saved strictly on your local browser.</p>

        <form class="settings-form" on:submit|preventDefault={saveSettings}>
          <div class="form-group">
            <label for="gh-token">GitHub Personal Access Token (PAT)</label>
            <input 
              id="gh-token" 
              type="password" 
              placeholder="ghp_xxxxxxxxxxxxxxxxxxxxxx" 
              bind:value={githubToken} 
              required
            />
            <small>Must have <code>repo</code> permissions to trigger workflows and retrieve artifacts.</small>
          </div>

          <div class="form-group">
            <label for="gh-repo">GitHub Repository Path</label>
            <input 
              id="gh-repo" 
              type="text" 
              placeholder="owner/repo" 
              bind:value={githubRepo} 
              required
            />
          </div>

          <div class="divider"></div>

          <h3>Dynamic DNS Settings (No-IP) [Optional]</h3>
          <p class="subtitle">Required to map deployments to a fixed host name automatically</p>

          <div class="form-group">
            <label for="ddns-host">DDNS Hostname</label>
            <input 
              id="ddns-host" 
              type="text" 
              placeholder="amass.hopto.org" 
              bind:value={ddnsHostname}
            />
          </div>

          <div class="form-group">
            <label for="ddns-user">No-IP Username / Email</label>
            <input 
              id="ddns-user" 
              type="text" 
              placeholder="yahyaazeem44@gmail.com" 
              bind:value={ddnsUsername}
            />
          </div>

          <div class="form-group">
            <label for="ddns-pass">No-IP Password</label>
            <input 
              id="ddns-pass" 
              type="password" 
              placeholder="••••••••••••" 
              bind:value={ddnsPassword}
            />
          </div>

          <button class="save-settings-btn" type="submit">
            Save Configuration
          </button>
        </form>
      </section>
    {/if}
  </div>
</main>

<style>
  /* Base Reset & Variables inside Component */
  :global(:root) {
    --bg-primary: #0b0f19;
    --card-bg: rgba(17, 24, 39, 0.7);
    --border-color: rgba(255, 255, 255, 0.08);
    --glow-color: rgba(16, 185, 129, 0.15);
    --text-primary: #f3f4f6;
    --text-secondary: #9ca3af;
    --accent-blue: #3b82f6;
    --accent-green: #10b981;
    --accent-red: #ef4444;
  }

  :global(body) {
    margin: 0;
    padding: 0;
    font-family: 'Inter', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
    background-color: var(--bg-primary);
    color: var(--text-primary);
    background-image: 
      radial-gradient(circle at 10% 20%, rgba(59, 130, 246, 0.05) 0%, transparent 40%),
      radial-gradient(circle at 90% 80%, rgba(16, 185, 129, 0.04) 0%, transparent 40%);
    min-height: 100vh;
  }

  .dashboard-root {
    display: flex;
    justify-content: center;
    align-items: flex-start;
    padding: 2.5rem 1rem;
    box-sizing: border-box;
    min-height: 100vh;
  }

  .glass-container {
    width: 100%;
    max-width: 1100px;
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 20px;
    padding: 2.5rem;
    backdrop-filter: blur(16px);
    -webkit-backdrop-filter: blur(16px);
    box-shadow: 0 20px 50px rgba(0, 0, 0, 0.4);
    box-sizing: border-box;
  }

  .dashboard-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 1.5rem;
    margin-bottom: 2rem;
    flex-wrap: wrap;
    gap: 1.5rem;
  }

  .logo-area {
    display: flex;
    align-items: center;
    position: relative;
  }

  .logo-area h1 {
    font-size: 1.5rem;
    font-weight: 800;
    margin: 0;
    letter-spacing: -0.025em;
  }

  .logo-area h1 span {
    font-weight: 300;
    color: var(--text-secondary);
  }

  .glow-sphere {
    position: absolute;
    width: 32px;
    height: 32px;
    background: var(--accent-green);
    filter: blur(15px);
    left: -10px;
    opacity: 0.3;
    pointer-events: none;
  }

  .tab-navigation {
    display: flex;
    background: rgba(255, 255, 255, 0.03);
    padding: 4px;
    border-radius: 10px;
    border: 1px solid var(--border-color);
  }

  .tab-btn {
    background: transparent;
    border: none;
    color: var(--text-secondary);
    padding: 8px 16px;
    border-radius: 8px;
    font-weight: 500;
    font-size: 0.9rem;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .tab-btn.active {
    background: rgba(255, 255, 255, 0.08);
    color: var(--text-primary);
  }

  /* Alerts */
  .alert-box {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 1rem 1.25rem;
    border-radius: 12px;
    margin-bottom: 1.5rem;
    font-size: 0.95rem;
  }

  .error-alert {
    background: rgba(239, 68, 68, 0.08);
    border: 1px solid rgba(239, 68, 68, 0.2);
    color: #fca5a5;
  }

  .success-alert {
    background: rgba(16, 185, 129, 0.08);
    border: 1px solid rgba(16, 185, 129, 0.2);
    color: #a7f3d0;
  }

  /* Panels Grid */
  .control-panel-grid {
    display: grid;
    grid-template-columns: 1fr 1.3fr;
    gap: 2rem;
  }

  @media (max-width: 850px) {
    .control-panel-grid {
      grid-template-columns: 1fr;
    }
  }

  .panel-card {
    background: rgba(255, 255, 255, 0.015);
    border: 1px solid var(--border-color);
    border-radius: 16px;
    padding: 1.75rem;
    display: flex;
    flex-direction: column;
    box-sizing: border-box;
  }

  .panel-card h2 {
    font-size: 1.2rem;
    font-weight: 700;
    margin-top: 0;
    margin-bottom: 0.25rem;
  }

  .subtitle {
    font-size: 0.85rem;
    color: var(--text-secondary);
    margin-top: 0;
    margin-bottom: 1.5rem;
  }

  /* Buttons & Region Cards */
  .button-list {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    margin-bottom: 2rem;
  }

  .deploy-btn {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1.25rem;
    background: rgba(255, 255, 255, 0.02);
    border: 1px solid var(--border-color);
    border-radius: 12px;
    cursor: pointer;
    color: var(--text-primary);
    text-align: left;
    transition: all 0.2s ease;
  }

  .deploy-btn:hover:not(:disabled) {
    background: rgba(255, 255, 255, 0.05);
    border-color: rgba(59, 130, 246, 0.4);
    box-shadow: 0 4px 20px rgba(59, 130, 246, 0.1);
  }

  .deploy-btn:active:not(:disabled) {
    transform: scale(0.98);
  }

  .btn-content {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }

  .region-title {
    font-size: 0.95rem;
    font-weight: 600;
  }

  .region-code {
    font-size: 0.8rem;
    color: var(--text-secondary);
  }

  .badge {
    font-size: 0.75rem;
    font-weight: 700;
    background: rgba(16, 185, 129, 0.15);
    color: var(--accent-green);
    padding: 4px 8px;
    border-radius: 6px;
    border: 1px solid rgba(16, 185, 129, 0.2);
  }

  .danger-zone {
    margin-top: auto;
    border-top: 1px solid var(--border-color);
    padding-top: 1.5rem;
  }

  .danger-zone h3 {
    font-size: 0.9rem;
    font-weight: 700;
    color: var(--accent-red);
    margin-top: 0;
    margin-bottom: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  .destroy-btn {
    width: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 0.5rem;
    padding: 1rem;
    background: rgba(239, 68, 68, 0.05);
    border: 1px solid rgba(239, 68, 68, 0.2);
    border-radius: 12px;
    color: #fca5a5;
    font-weight: 600;
    font-size: 0.9rem;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .destroy-btn:hover:not(:disabled) {
    background: rgba(239, 68, 68, 0.1);
    border-color: var(--accent-red);
    box-shadow: 0 4px 20px rgba(239, 68, 68, 0.15);
  }

  /* Status Card */
  .status-indicator-block {
    background: rgba(255, 255, 255, 0.01);
    border: 1px solid var(--border-color);
    border-radius: 12px;
    padding: 1.25rem;
    margin-bottom: 1.5rem;
    display: flex;
    flex-direction: column;
    gap: 1rem;
    position: relative;
  }

  .status-info {
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  .status-info .label {
    font-size: 0.9rem;
    color: var(--text-secondary);
  }

  .value-badge {
    font-size: 0.85rem;
    font-weight: 700;
    padding: 4px 10px;
    border-radius: 8px;
    letter-spacing: 0.025em;
  }

  .status-idle { background: rgba(156, 163, 175, 0.1); color: #d1d5db; border: 1px solid rgba(156, 163, 175, 0.2); }
  .status-queued { background: rgba(245, 158, 11, 0.1); color: #fcd34d; border: 1px solid rgba(245, 158, 11, 0.2); }
  .status-in-progress { background: rgba(59, 130, 246, 0.1); color: #93c5fd; border: 1px solid rgba(59, 130, 246, 0.2); }
  .status-completed { background: rgba(16, 185, 129, 0.1); color: #a7f3d0; border: 1px solid rgba(16, 185, 129, 0.2); }
  .status-failed { background: rgba(239, 68, 68, 0.1); color: #fca5a5; border: 1px solid rgba(239, 68, 68, 0.2); }

  /* Progress Bar */
  .progress-bar-container {
    width: 100%;
    height: 6px;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    overflow: hidden;
  }

  .progress-bar-fill {
    height: 100%;
    background: linear-gradient(90deg, var(--accent-blue), var(--accent-green));
    border-radius: 10px;
    transition: width 0.3s ease;
  }

  .progress-details {
    display: flex;
    justify-content: space-between;
    font-size: 0.75rem;
    color: var(--text-secondary);
  }

  /* Output Block */
  .output-block-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: 1.5rem;
    margin-bottom: 0.75rem;
  }

  .output-block-header h2 {
    font-size: 0.95rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--text-secondary);
    margin: 0;
  }

  .actions {
    display: flex;
    gap: 0.5rem;
  }

  .action-icon-btn {
    background: rgba(255, 255, 255, 0.03);
    border: 1px solid var(--border-color);
    color: var(--text-primary);
    padding: 6px 12px;
    border-radius: 6px;
    font-size: 0.75rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .action-icon-btn:hover {
    background: rgba(255, 255, 255, 0.08);
    border-color: rgba(255, 255, 255, 0.2);
  }

  .code-output {
    background: #060913;
    border: 1px solid var(--border-color);
    border-radius: 10px;
    padding: 1.25rem;
    font-family: 'Fira Code', 'Courier New', Courier, monospace;
    font-size: 0.8rem;
    overflow-x: auto;
    max-height: 250px;
    color: #e2e8f0;
    margin: 0 0 1.5rem 0;
  }

  .cert-header {
    border-top: 1px solid var(--border-color);
    padding-top: 1.5rem;
  }

  .cert-code {
    max-height: 120px;
  }

  .empty-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 4rem 2rem;
    text-align: center;
    color: var(--text-secondary);
    margin: auto 0;
  }

  .empty-state svg {
    margin-bottom: 1rem;
    opacity: 0.3;
    color: var(--accent-blue);
  }

  .empty-state h3 {
    margin: 0 0 0.5rem 0;
    color: var(--text-primary);
    font-size: 1.05rem;
  }

  .empty-state p {
    margin: 0;
    font-size: 0.85rem;
    max-width: 320px;
    line-height: 1.5;
  }

  /* Spinner */
  .status-pulse-spinner {
    position: absolute;
    width: 20px;
    height: 20px;
    right: 1.25rem;
    top: 1.25rem;
  }

  .double-bounce1, .double-bounce2 {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    background-color: var(--accent-blue);
    opacity: 0.6;
    position: absolute;
    top: 0;
    left: 0;
    animation: sk-bounce 2.0s infinite ease-in-out;
  }

  .double-bounce2 {
    animation-delay: -1.0s;
    background-color: var(--accent-green);
  }

  @keyframes sk-bounce {
    0%, 100% { transform: scale(0.0); }
    50% { transform: scale(1.0); }
  }

  /* Settings Panel */
  .settings-form {
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
  }

  .form-group {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .form-group label {
    font-size: 0.9rem;
    font-weight: 600;
  }

  .form-group input {
    background: rgba(255, 255, 255, 0.02);
    border: 1px solid var(--border-color);
    padding: 0.85rem 1rem;
    border-radius: 10px;
    color: var(--text-primary);
    font-size: 0.95rem;
    transition: all 0.2s ease;
  }

  .form-group input:focus {
    outline: none;
    border-color: rgba(59, 130, 246, 0.5);
    box-shadow: 0 0 10px rgba(59, 130, 246, 0.15);
    background: rgba(255, 255, 255, 0.04);
  }

  .form-group small {
    font-size: 0.75rem;
    color: var(--text-secondary);
  }

  .divider {
    height: 1px;
    background: var(--border-color);
    margin: 1rem 0;
  }

  .settings-card h3 {
    margin: 0 0 0.25rem 0;
    font-size: 1.1rem;
  }

  .save-settings-btn {
    margin-top: 1rem;
    padding: 1rem;
    background: var(--accent-blue);
    color: white;
    border: none;
    border-radius: 10px;
    font-weight: 700;
    font-size: 0.95rem;
    cursor: pointer;
    transition: all 0.2s ease;
    box-shadow: 0 4px 15px rgba(59, 130, 246, 0.3);
  }

  .save-settings-btn:hover {
    background: #2563eb;
    box-shadow: 0 4px 20px rgba(59, 130, 246, 0.45);
  }

  .save-settings-btn:active {
    transform: scale(0.99);
  }

  /* Disabled state styling global */
  button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
    box-shadow: none !important;
    transform: none !important;
  }
</style>
