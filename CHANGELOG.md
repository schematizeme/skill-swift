# Changelog — schematize-swift

Todas as mudanças relevantes deste pacote, no formato [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
com versionamento [SemVer](https://semver.org/lang/pt-BR/).

## [0.2.0] — 2026-09-30

Pedido do dono, por **custo**: o orquestrador não desenvolve; ação onerosa vira micro-tasks baratas; `sonnet` é o default dos subagents e `opus` só entra após falha.

### Adicionado
- **Piso "Orquestrador não desenvolve; subagent barato executa"** no `assets/CLAUDE.md` e no `SKILL.md`: o agent principal só planeja, despacha e revisa; ação onerosa vira micro-tasks para subagents em `sonnet` (falhou → o mesmo subagent corrige → re-decompõe → só então `opus`, com motivo). Detalhe na base: `schematize-engineering` → `references/orquestracao.md` §9.

### Mantido (piso inalterado)
- Todos os pisos anteriores e o gate de `scripts/` seguem exatamente como estavam; a mudança é só de orquestração, não de código.

## [0.1.0] — 2026-08-21

Primeira versão. A `schematize-mobile` promete escolha *"nativo vs cross por fit + ADR"* e **não havia skill por trás de nenhuma das opções** — promessa **publicada e não sustentada** (vistoria de 2026-08-21). Esta skill é uma das quatro peças que fecham isso, com `schematize-kotlin`, `schematize-dart` e o conserto da própria `schematize-mobile` (v0.3.0), no mesmo marco.

### Adicionado
- **`references/piso.md`** — o piso de linguagem: **opcional é tipo, não sugestão** (cada `!` é um `fatalError` que você escolheu adiar, e no app instalado é **crash na mão do usuário**, não exceção capturável); **concorrência estruturada** com `async/await`, **strict concurrency do Swift 6** (data race vira erro de compilação), `@MainActor` **só no que toca UI** (marcar o mundo para calar o compilador é serializar o app), `Sendable` como contrato, **cancelamento cooperativo** e a **reentrância do `actor`** — o estado pode mudar **durante** um `await` dentro dele; **ARC não é GC** (ciclo de retenção é vazamento; `unowned` errado é crash, não `nil`); erro tipado; segurança do cliente; teste.
- **`references/plataforma.md`** — SwiftPM com **`Package.resolved` commitado** (é o lockfile), build no CI com **simulador fixado** (simulador flutuante é flaky garantido), assinatura em cofre, `@available` com caminho alternativo **testado**, e a posição sobre **server-side Swift**: não é backend do rol — entra por ADR de exceção.
- **`scripts/check-swift.sh`** + **`check-swift.test.sh`** (**9 casos**, 7 vermelhos): `try!`/`as!`, `catch {}` vazio, `DispatchSemaphore`, credencial em `UserDefaults`, `NSAllowsArbitraryLoads` (no código **e** no `Info.plist`), `@unchecked Sendable` sem justificativa, `unowned`, URLSession sem timeout. Teste **pode** usar force-unwrap — a regra distingue.

### Honestidade sobre o alcance
- A toolchain Swift **não roda na máquina de referência do catálogo** (Linux). O gate é **textual** e **diz isso na saída**; onde houver `swift build`/SwiftLint, **são eles que mandam**. *Um verificador que finge ser compilador é pior que nenhum.* Os números de versão moram no anexo volátil, com a mesma ressalva.
