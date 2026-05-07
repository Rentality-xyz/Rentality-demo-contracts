const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(process.cwd(), 'migration-data', 'base-sepolia');
const OUTPUT_PATH = path.join(DATA_DIR, 'legacy-validation-report.json');

const SNAPSHOT_FILES = [
  'legacy-cars.json',
  'legacy-trips.json',
  'legacy-insurance.json',
  'legacy-investments.json',
  'legacy-referrals.json',
  'legacy-profiles.json',
  'legacy-pricing-payments.json',
];

function readJson(fileName) {
  const filePath = path.join(DATA_DIR, fileName);
  if (!fs.existsSync(filePath)) {
    return null;
  }

  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function walk(value, visitor, pathParts = []) {
  visitor(value, pathParts);

  if (Array.isArray(value)) {
    value.forEach((item, index) => walk(item, visitor, [...pathParts, index]));
    return;
  }

  if (value && typeof value === 'object') {
    Object.entries(value).forEach(([key, item]) => walk(item, visitor, [...pathParts, key]));
  }
}

function findUnavailable(snapshot) {
  const unavailable = [];

  walk(snapshot, (value, pathParts) => {
    if (value && typeof value === 'object' && value.unavailable === true) {
      unavailable.push({
        path: pathParts.join('.'),
        label: value.label || null,
        reason: value.reason || null,
      });
    }
  });

  return unavailable;
}

function summarize(snapshot, fileName) {
  if (!snapshot) {
    return {
      fileName,
      missing: true,
    };
  }

  const unavailable = findUnavailable(snapshot);
  const summary = {
    fileName,
    missing: false,
    exportedAt: snapshot.exportedAt || null,
    contracts: snapshot.contracts || {},
    totals: snapshot.totals || {},
    unavailableCount: unavailable.length,
    unavailable,
  };

  if (fileName === 'legacy-cars.json') {
    summary.cars = {
      totalSupply: snapshot.totalSupply,
      exportedCars: snapshot.exportedCars,
      skippedCars: snapshot.skippedCars || [],
    };
  }

  if (fileName === 'legacy-trips.json') {
    summary.trips = {
      totalTripCount: snapshot.totalTripCount,
      exportedTrips: snapshot.exportedTrips,
      unavailableTrips: snapshot.unavailableTrips || [],
    };
  }

  if (fileName === 'legacy-investments.json') {
    summary.investments = {
      callContext: snapshot.callContext || {},
    };
  }

  if (fileName === 'legacy-profiles.json') {
    summary.profiles = {
      global: snapshot.global || {},
    };
  }

  return summary;
}

function main() {
  const snapshots = Object.fromEntries(SNAPSHOT_FILES.map((fileName) => [fileName, readJson(fileName)]));
  const summaries = SNAPSHOT_FILES.map((fileName) => summarize(snapshots[fileName], fileName));
  const missingFiles = summaries.filter((summary) => summary.missing).map((summary) => summary.fileName);
  const unavailableTotal = summaries.reduce((total, summary) => total + (summary.unavailableCount || 0), 0);

  const report = {
    generatedAt: new Date().toISOString(),
    dataDir: DATA_DIR,
    missingFiles,
    unavailableTotal,
    summaries,
    status: missingFiles.length === 0 ? 'complete' : 'incomplete',
  };

  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(report, null, 2));

  console.log(`Validation status: ${report.status}`);
  console.log(`Snapshots found: ${SNAPSHOT_FILES.length - missingFiles.length}/${SNAPSHOT_FILES.length}`);
  console.log(`Unavailable calls: ${unavailableTotal}`);
  console.log(`Report written to ${OUTPUT_PATH}`);

  for (const summary of summaries) {
    if (summary.missing) {
      console.log(`- ${summary.fileName}: missing`);
      continue;
    }

    console.log(`- ${summary.fileName}: unavailable=${summary.unavailableCount}`);
  }
}

main();
