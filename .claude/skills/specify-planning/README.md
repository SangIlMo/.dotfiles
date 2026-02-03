# Specify-Planning Skill

Specification-driven development toolkit for Claude Code, integrating GitHub's Spec-Kit methodology.

## Quick Start

### New Project

```
/specify-init my-project
/specify-constitution
/specify-requirements user-authentication
/specify-plan user-authentication
/specify-tasks user-authentication --auto-create
```

### Existing Project

```
/specify-init
/specify-constitution
/specify-requirements new-feature
```

## Commands

| Command | Purpose |
|---------|---------|
| `/specify-init [name]` | Initialize .spec/ directory structure |
| `/specify-constitution` | Create/update project governance |
| `/specify-requirements <feature>` | Document feature requirements |
| `/specify-plan <feature>` | Create technical implementation plan |
| `/specify-tasks <feature>` | Break down into executable tasks |
| `/specify-validate <feature>` | Validate specification quality |

## Workflow

```
Constitution (project-wide)
    ↓
Specification (what & why)
    ↓
Plan (how - technical)
    ↓
Tasks (executable units)
    ↓
Implement (guided by specs)
```

## Key Features

- **Progressive Refinement**: Each stage builds on the previous
- **AI-Optimized**: Clear specs = better AI implementation
- **Git Integration**: Automatic branching and commits
- **Task Orchestration**: Generates Claude Code tasks
- **Multi-Perspective Validation**: Swarm mode for expert reviews
- **Living Documentation**: Specs stay current

## Project Structure

```
project-root/
├── .spec/
│   ├── constitution.md
│   ├── features/
│   │   ├── 001-feature-name/
│   │   │   ├── specification.md
│   │   │   ├── plan.md
│   │   │   └── tasks.md
│   │   └── README.md
│   └── .specrc
└── [project files]
```

## Examples

See `examples/` directory for complete specifications:
- `examples/constitutions/saas-platform.md`
- `examples/specifications/user-auth-spec.md`
- `examples/plans/user-auth-plan.md`
- `examples/tasks/user-auth-tasks.md`

## Templates

Customize templates in your project at `.spec/templates/` or use defaults from `templates/`:
- `constitution.template.md`
- `specification.template.md`
- `plan.template.md`
- `tasks.template.md`

## Validation

Run validation scripts:
```bash
~/.claude/skills/specify-planning/scripts/validate-spec.sh .spec/features/001-my-feature/specification.md
~/.claude/skills/specify-planning/scripts/spec-status.sh
```

Or use the validate command:
```
/specify-validate my-feature --swarm
```

## Documentation

- `SKILL.md` - Complete skill reference
- `references/methodology.md` - Spec-driven development philosophy
- `references/*-guide.md` - Writing guides for each stage
- `references/validation-checklists.md` - Quality criteria

## Integration

Works seamlessly with Claude Code features:
- **Orchestration**: Auto-selects Sequential/Parallel/Swarms modes
- **Auto-Commit**: Commits validated specs automatically
- **Git Protection**: Safe pushes with branch checks
- **Task System**: Generates and tracks implementation tasks

## Version

1.0.0

## License

MIT - See LICENSE.txt
