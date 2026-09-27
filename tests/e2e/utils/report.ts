import fs from 'fs';
import path from 'path';

export type Severity = 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';

export interface ActionRecord {
  role: 'ADMIN' | 'TEACHER' | 'STUDENT';
  page: string;
  action: string;
  result: 'PASS' | 'FAIL';
  errorDetail: string;
  screenshotPath: string;
}

export interface IssueRecord {
  severity: Severity;
  role: string;
  page: string;
  reproSteps: string;
  expected: string;
  actual: string;
  rootCause: string;
  fix: string;
}

const severityOrder: Record<Severity, number> = {
  CRITICAL: 0,
  HIGH: 1,
  MEDIUM: 2,
  LOW: 3,
};

export class E2EReport {
  private readonly actions: ActionRecord[] = [];
  private readonly issues: IssueRecord[] = [];

  addAction(record: ActionRecord) {
    this.actions.push(record);
  }

  addIssue(issue: IssueRecord) {
    this.issues.push(issue);
  }

  write(outDir: string) {
    fs.mkdirSync(outDir, { recursive: true });

    const dedupedIssues = this.dedupeIssues().sort((a, b) => severityOrder[a.severity] - severityOrder[b.severity]);

    const jsonPath = path.join(outDir, 'e2e-action-report.json');
    const mdPath = path.join(outDir, 'e2e-action-report.md');

    fs.writeFileSync(
      jsonPath,
      JSON.stringify(
        {
          generated_at: new Date().toISOString(),
          actions: this.actions,
          issues: dedupedIssues,
        },
        null,
        2,
      ),
      'utf8',
    );

    const lines: string[] = [];
    lines.push('# E2E Browser Action Report');
    lines.push('');
    lines.push('## Action Matrix');
    lines.push('');
    lines.push('| Role | Page | Element/Action | Result | Error Detail | Screenshot |');
    lines.push('| --- | --- | --- | --- | --- | --- |');
    for (const row of this.actions) {
      lines.push(`| ${row.role} | ${escapePipe(row.page)} | ${escapePipe(row.action)} | ${row.result} | ${escapePipe(row.errorDetail || '-')} | ${escapePipe(row.screenshotPath || '-')} |`);
    }

    lines.push('');
    lines.push('## قائمة المشاكل');
    lines.push('');
    lines.push('| Severity | Role | Page | Repro Steps | Expected | Actual | Root Cause | Fix |');
    lines.push('| --- | --- | --- | --- | --- | --- | --- | --- |');
    for (const issue of dedupedIssues) {
      lines.push(
        `| ${issue.severity} | ${issue.role} | ${escapePipe(issue.page)} | ${escapePipe(issue.reproSteps)} | ${escapePipe(issue.expected)} | ${escapePipe(issue.actual)} | ${escapePipe(issue.rootCause)} | ${escapePipe(issue.fix)} |`,
      );
    }

    fs.writeFileSync(mdPath, lines.join('\n'), 'utf8');
    return { jsonPath, mdPath };
  }

  private dedupeIssues() {
    const seen = new Set<string>();
    const unique: IssueRecord[] = [];

    for (const issue of this.issues) {
      const key = `${issue.severity}|${issue.role}|${issue.page}|${issue.reproSteps}|${issue.actual}`;
      if (seen.has(key)) {
        continue;
      }
      seen.add(key);
      unique.push(issue);
    }

    return unique;
  }
}

function escapePipe(value: string) {
  return String(value).replace(/\|/g, '\\|').replace(/\n/g, '<br>');
}
