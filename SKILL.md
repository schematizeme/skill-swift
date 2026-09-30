---
name: schematize-swift
metadata:
  version: 0.2.0
description: O piso de SWIFT da casa (cliente Apple — iOS/iPadOS/macOS). Rege opcional como tipo e não sugestão (**force-unwrap é `fatalError` adiado**, e no app instalado é crash na mão do usuário); concorrência estruturada com `async/await` + **strict concurrency do Swift 6** (data race vira erro de compilação), `@MainActor` só no que toca UI, `Sendable` como contrato, cancelamento cooperativo, e a reentrância do `actor` (o estado muda durante o `await`); memória sob ARC (ciclo de retenção é vazamento; `[weak self]`; `unowned` é crash, não `nil`); erro como valor tipado, nunca `catch {}`; segredo nunca no bundle e credencial no Keychain, nunca `UserDefaults`; SwiftPM com `Package.resolved` commitado; e a fronteira com a `schematize-mobile`, que manda no que é de app. Traz gate executável.
---
<!-- cross-skill: linguagens.md -> schematize-engineering -->

# O piso de Swift da casa (schematize-swift)

Recorte de **linguagem** para o cliente Apple. A base agnóstica é a **`schematize-engineering`**; o
piso de **app** (offline-first, IAM mobile, push, lojas, testes no device) é da
**`schematize-mobile`** — e, no que é de app, **ela manda**. Aqui fica o que é da linguagem e da
toolchain.

**Versão:** skill `schematize-swift` v0.2.0. Changelog em `CHANGELOG.md`.

## Por que ela nasceu

A `schematize-mobile` promete escolha *"nativo vs cross por fit + ADR"* — e não havia **skill por
trás de nenhuma das opções**: promessa publicada e não sustentada (vistoria de 2026-08-21). Esta
skill é uma das quatro peças que fecham isso, junto com `schematize-kotlin`, `schematize-dart` e o
conserto da própria `schematize-mobile`.

## Comandos (Claude Code)

| Comando | O que faz |
|---|---|
| `/swift-help` | lista os comandos |
| `/swift-load` | carrega à força o corpo normativo (piso, plataforma) |
| `/swift-review` | revisa `.swift` contra o piso: roda o gate e lê o que a máquina não lê |
| `/swift-claude` | cria/mescla o `CLAUDE.md` sempre-on na raiz do repo |
| `/swift-cc` · `/swift-handoff` | context compact / handoff arquivado |

## Como usar

1. **O que é de app é da `schematize-mobile`** — comece por lá se a pergunta é offline, IAM, push,
   loja ou teste no device.
2. **Rode o gate:** `bash scripts/check-swift.sh .` — `0` passa · `1` reprova · `2` **nada para
   verificar** (que não é aprovação). Ele é **textual**: onde houver compilador e SwiftLint, **são
   eles que mandam**.
3. **Piso de linguagem** em `references/piso.md`; **toolchain e distribuição** em
   `references/plataforma.md`.

Mapa de references:

| Tarefa | Reference |
|---|---|
| Opcional, concorrência estruturada (Swift 6 mode, `@MainActor`, `Sendable`, cancelamento, reentrância do actor), ARC e ciclo de retenção, erro tipado, segurança do cliente, teste | `references/piso.md` |
| SwiftPM e `Package.resolved`, build no CI com simulador fixado, assinatura em cofre, `@available`, Swift fora do iOS, interop Obj-C/C | `references/plataforma.md` |
| Versões e ferramental, com data de verificação **e a ressalva de que a toolchain não roda na máquina de referência** | `references/stack-versoes.md` |

## Pisos inegociáveis (vetam o atalho)

1. **Force-unwrap é `fatalError` adiado.** `try!`/`as!` são VETADOS em produção; `!` só com
   invariante real — e aí `precondition` com mensagem diz o que quebrou, o `!` não diz nada.
2. **Concorrência estruturada:** `async/await`; **`DispatchSemaphore` para esperar async é VETADO**
   (deadlock na main thread esperando acontecer).
3. **Strict concurrency (Swift 6 mode) ligado** no código novo — é o que transforma data race em
   erro de compilação em vez de crash intermitente.
4. **`@MainActor` só no que toca UI.** Marcar o mundo de `@MainActor` para calar o compilador é
   serializar o app.
5. **Cancelamento é cooperativo:** operação longa checa `Task.isCancelled`, senão continua rodando
   depois que a tela sumiu.
6. **Ciclo de retenção é vazamento:** `[weak self]` no que sobrevive à tela; delegate é `weak`;
   `unowned` só quando o dono é garantidamente mais longevo — se não for, é **crash**, não `nil`.
7. **Erro é valor tipado.** `catch { }` vazio é VETADO; `fatalError` só em invariante de
   programação, nunca em erro de I/O, rede ou dado do usuário.
8. **Segredo nunca no bundle** (tudo no `.ipa` é legível com `strings`); credencial no **Keychain**,
   nunca `UserDefaults`; `NSAllowsArbitraryLoads` VETADO.
9. **`Package.resolved` commitado** e toolchain declarada — sem lockfile, duas máquinas resolvem
   versões diferentes.
10. **Warnings são erros no CI.** Em Swift, warning é quase sempre defeito real.
11. **Orquestrador não desenvolve; subagent barato executa.** O agent principal só planeja, despacha e revisa; ação onerosa vira micro-tasks para subagents em `sonnet` (falhou → o mesmo subagent corrige → re-decompõe → só então `opus`, com motivo). **Sem frota ociosa:** idle com pendência volta ao trabalho; dependente de outro agent → mata e enfileira com gatilho; terminou → mata. Detalhe: `schematize-engineering` → `references/orquestracao.md` §9.

## Relação com as outras skills

- **`schematize-mobile`** — o piso de **app**. Onde as duas falarem do mesmo assunto, **a mobile
  manda** no que é de produto/plataforma; aqui manda o que é de linguagem.
- **`schematize-engineering`** — a base e o rol. **Server-side Swift não é backend do rol**: entra
  só por ADR de exceção.
- **`schematize-qa`** — a disciplina de teste; aqui só muda o runner (`swift-testing`/XCTest).
- **`schematize-pentest`** — o lado ofensivo (segredo no bundle, pinning, deep link hostil).
