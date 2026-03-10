#!/usr/bin/env node
/**
 * Apify Actor Runner - Runs Apify actors and exports results.
 * Embedded from: github.com/apify/agent-skills (apify-ultimate-scraper)
 * Version: 1.3.0
 *
 * Usage:
 *   # Quick answer (display in chat, no file saved)
 *   node scripts/run_actor.js --actor ACTOR_ID --input '{}'
 *
 *   # Export to file
 *   node scripts/run_actor.js --actor ACTOR_ID --input '{}' --output leads.csv --format csv
 *
 * Env: APIFY_TOKEN or APIFY_API_TOKEN (either works)
 */

import { parseArgs } from 'node:util';
import { writeFileSync, readFileSync, statSync } from 'node:fs';

const USER_AGENT = 'osint-skill/3.1 (apify-agent-skills/apify-ultimate-scraper-1.3.0)';

function parseCliArgs() {
    const options = {
        actor: { type: 'string', short: 'a' },
        input: { type: 'string', short: 'i' },
        output: { type: 'string', short: 'o' },
        format: { type: 'string', short: 'f', default: 'csv' },
        timeout: { type: 'string', short: 't', default: '600' },
        'poll-interval': { type: 'string', default: '5' },
        help: { type: 'boolean', short: 'h' },
    };

    const { values } = parseArgs({ options, allowPositionals: false });

    if (values.help) {
        printHelp();
        process.exit(0);
    }

    if (!values.actor) {
        console.error('Error: --actor is required');
        printHelp();
        process.exit(1);
    }

    if (!values.input) {
        console.error('Error: --input is required');
        printHelp();
        process.exit(1);
    }

    return {
        actor: values.actor,
        input: values.input,
        output: values.output,
        format: values.format || 'csv',
        timeout: parseInt(values.timeout, 10),
        pollInterval: parseInt(values['poll-interval'], 10),
    };
}

function printHelp() {
    console.log(`
Apify Actor Runner (embedded in OSINT skill)

Usage:
  node scripts/run_actor.js --actor ACTOR_ID --input '{}'

Options:
  --actor, -a       Actor ID (e.g., compass/crawler-google-places) [required]
  --input, -i       Actor input as JSON string [required]
  --output, -o      Output file path (optional - if not provided, displays quick answer)
  --format, -f      Output format: csv, json (default: csv)
  --timeout, -t     Max wait time in seconds (default: 600)
  --poll-interval   Seconds between status checks (default: 5)
  --help, -h        Show this help message

Env: APIFY_TOKEN or APIFY_API_TOKEN (either works)
`);
}

async function startActor(token, actorId, inputJson) {
    const apiActorId = actorId.replace('/', '~');
    const url = `https://api.apify.com/v2/acts/${apiActorId}/runs?token=${encodeURIComponent(token)}`;

    let data;
    try {
        data = JSON.parse(inputJson);
    } catch (e) {
        console.error(`Error: Invalid JSON input: ${e.message}`);
        process.exit(1);
    }

    const response = await fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'User-Agent': USER_AGENT,
        },
        body: JSON.stringify(data),
    });

    if (response.status === 404) {
        console.error(`Error: Actor '${actorId}' not found`);
        process.exit(1);
    }

    if (!response.ok) {
        const text = await response.text();
        console.error(`Error: API request failed (${response.status}): ${text}`);
        process.exit(1);
    }

    const result = await response.json();
    return {
        runId: result.data.id,
        datasetId: result.data.defaultDatasetId,
    };
}

async function pollUntilComplete(token, runId, timeout, interval) {
    const url = `https://api.apify.com/v2/actor-runs/${runId}?token=${encodeURIComponent(token)}`;
    const startTime = Date.now();
    let lastStatus = null;

    while (true) {
        const response = await fetch(url);
        if (!response.ok) {
            const text = await response.text();
            console.error(`Error: Failed to get run status: ${text}`);
            process.exit(1);
        }

        const result = await response.json();
        const status = result.data.status;

        if (status !== lastStatus) {
            console.log(`Status: ${status}`);
            lastStatus = status;
        }

        if (['SUCCEEDED', 'FAILED', 'ABORTED', 'TIMED-OUT'].includes(status)) {
            return status;
        }

        const elapsed = (Date.now() - startTime) / 1000;
        if (elapsed > timeout) {
            console.error(`Warning: Timeout after ${timeout}s, actor still running`);
            return 'TIMED-OUT';
        }

        await sleep(interval * 1000);
    }
}

async function downloadResults(token, datasetId, outputPath, format) {
    const url = `https://api.apify.com/v2/datasets/${datasetId}/items?token=${encodeURIComponent(token)}&format=json`;

    const response = await fetch(url, {
        headers: { 'User-Agent': USER_AGENT },
    });

    if (!response.ok) {
        const text = await response.text();
        console.error(`Error: Failed to download results: ${text}`);
        process.exit(1);
    }

    const data = await response.json();

    if (format === 'json') {
        writeFileSync(outputPath, JSON.stringify(data, null, 2));
    } else {
        if (data.length > 0) {
            const fieldnames = Object.keys(data[0]);
            const csvLines = [fieldnames.join(',')];

            for (const row of data) {
                const values = fieldnames.map((key) => {
                    let value = row[key];
                    if (typeof value === 'string' && value.length > 200) {
                        value = value.slice(0, 200) + '...';
                    } else if (Array.isArray(value) || (typeof value === 'object' && value !== null)) {
                        value = JSON.stringify(value) || '';
                    }
                    if (value === null || value === undefined) return '';
                    const strValue = String(value);
                    if (strValue.includes(',') || strValue.includes('"') || strValue.includes('\n')) {
                        return `"${strValue.replace(/"/g, '""')}"`;
                    }
                    return strValue;
                });
                csvLines.push(values.join(','));
            }
            writeFileSync(outputPath, csvLines.join('\n'));
        } else {
            writeFileSync(outputPath, '');
        }
    }

    console.log(`Saved to: ${outputPath}`);
}

async function displayQuickAnswer(token, datasetId) {
    const url = `https://api.apify.com/v2/datasets/${datasetId}/items?token=${encodeURIComponent(token)}&format=json`;

    const response = await fetch(url, {
        headers: { 'User-Agent': USER_AGENT },
    });

    if (!response.ok) {
        const text = await response.text();
        console.error(`Error: Failed to download results: ${text}`);
        process.exit(1);
    }

    const data = await response.json();
    const total = data.length;

    if (total === 0) {
        console.log('\nNo results found.');
        return;
    }

    console.log(`\n${'='.repeat(60)}`);
    console.log(`TOP 5 RESULTS (of ${total} total)`);
    console.log('='.repeat(60));

    for (let i = 0; i < Math.min(5, data.length); i++) {
        const item = data[i];
        console.log(`\n--- Result ${i + 1} ---`);

        for (const [key, value] of Object.entries(item)) {
            let displayValue = value;
            if (typeof value === 'string' && value.length > 100) {
                displayValue = value.slice(0, 100) + '...';
            } else if (Array.isArray(value) || (typeof value === 'object' && value !== null)) {
                const jsonStr = JSON.stringify(value);
                displayValue = jsonStr.length > 100 ? jsonStr.slice(0, 100) + '...' : jsonStr;
            }
            console.log(`  ${key}: ${displayValue}`);
        }
    }

    console.log(`\n${'='.repeat(60)}`);
    if (total > 5) {
        console.log(`Showing 5 of ${total} results.`);
    }
    console.log(`Full data: https://console.apify.com/storage/datasets/${datasetId}`);
    console.log('='.repeat(60));
}

function reportSummary(outputPath, format) {
    const stats = statSync(outputPath);
    const content = readFileSync(outputPath, 'utf-8');
    let count;
    try {
        if (format === 'json') {
            const data = JSON.parse(content);
            count = Array.isArray(data) ? data.length : 1;
        } else {
            const lines = content.split('\n').filter((line) => line.trim());
            count = Math.max(0, lines.length - 1);
        }
    } catch {
        count = 'unknown';
    }
    console.log(`Records: ${count}`);
    console.log(`Size: ${stats.size.toLocaleString()} bytes`);
}

function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
    const args = parseCliArgs();

    // Accept both APIFY_TOKEN and APIFY_API_TOKEN
    const token = process.env.APIFY_TOKEN || process.env.APIFY_API_TOKEN;
    if (!token) {
        console.error('Error: APIFY_TOKEN not found');
        console.error('Set APIFY_TOKEN or APIFY_API_TOKEN env var');
        console.error('Get your token: https://console.apify.com/account/integrations');
        process.exit(1);
    }

    console.log(`Starting actor: ${args.actor}`);
    const { runId, datasetId } = await startActor(token, args.actor, args.input);
    console.log(`Run ID: ${runId}`);
    console.log(`Dataset ID: ${datasetId}`);

    const status = await pollUntilComplete(token, runId, args.timeout, args.pollInterval);

    if (status !== 'SUCCEEDED') {
        console.error(`Error: Actor run ${status}`);
        console.error(`Details: https://console.apify.com/actors/runs/${runId}`);
        process.exit(1);
    }

    if (args.output) {
        await downloadResults(token, datasetId, args.output, args.format);
        reportSummary(args.output, args.format);
    } else {
        await displayQuickAnswer(token, datasetId);
    }
}

main().catch((err) => {
    console.error(`Error: ${err.message}`);
    process.exit(1);
});
