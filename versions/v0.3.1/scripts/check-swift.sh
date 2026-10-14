#!/usr/bin/env bash
# schematize-swift — o gate. Cobra o piso de `references/piso.md` sobre o Swift do repo.
#
# HONESTIDADE SOBRE O ALCANCE: a toolchain Swift não roda em Linux por default, e este gate é
# TEXTUAL — ele não compila nada. Onde `swift build`/`swiftlint` existirem, são ELES que mandam, e o
# gate diz isso na saída. Um verificador que finge ser compilador é pior que nenhum.
#
# strict-ok: COLETOR — varre tudo e soma; com `set -e` reportaria um achado em vez de todos
# (`schematize-shell` -> `references/piso.md` secao 1)
set -uo pipefail

raiz="${1:-.}"
erros=(); avisos=()

arquivos=()
while IFS= read -r -d '' f; do arquivos+=("$f"); done < <(
  find "$raiz" -type f -name '*.swift' \
    -not -path '*/.build/*' -not -path '*/.git/*' -not -path '*/Pods/*' \
    -not -path '*/DerivedData/*' -not -path '*/versions/*' -print0 2>/dev/null
)
if [ "${#arquivos[@]}" -eq 0 ]; then
  echo "✖ nenhum .swift em $raiz — nada para verificar (ausência de material não é aprovação)." >&2
  exit 2
fi

command -v swift >/dev/null 2>&1 \
  || avisos+=("toolchain Swift ausente nesta máquina: o gate rodou só as regras TEXTUAIS. Onde houver \`swift build\`/SwiftLint, são eles que mandam")

for f in "${arquivos[@]}"; do
  nome="${f#"$raiz"/}"
  # sem comentário de linha e sem string: as regras olham CÓDIGO. (Ordem: string primeiro.)
  codigo="$(sed -e 's/"[^"]*"/""/g' -e 's|//.*$||' "$f")"
  ehTeste=0
  case "$nome" in *Test*) ehTeste=1 ;; esac   # cobre Tests/, *Tests.swift e *Test.swift

  # 1. force-unwrap e amigos — o crash que você escolheu adiar
  if [ "$ehTeste" = 0 ]; then
    grep -qE '\btry!' <<< "$codigo" && erros+=("$nome: \`try!\` — VETADO em produção (piso.md secao 1)")
    grep -qE '\bas!' <<< "$codigo"  && erros+=("$nome: \`as!\` — cast forçado: crash na mão do usuário quando o tipo mudar")
    # `[]A-Za-z_)]` com o `]` PRIMEIRO: dentro de classe POSIX a barra invertida é LITERAL, e
    # `[A-Za-z_)\]]` exigia um `]` logo depois — a regra nunca casava (gate cego parece verde).
    grep -qE '[]A-Za-z_)]![]. ),;]|[]A-Za-z_)]!$' <<< "$codigo" \
      && ! grep -qE '#\s*swift-ok:' "$f" \
      && avisos+=("$nome: possível force-unwrap (\`!\`) — cada um é um fatalError adiado; use guard let / ?? / throws")
  fi

  # 2. erro engolido
  grep -qE 'catch\s*\{\s*\}' <<< "$codigo" && erros+=("$nome: \`catch { }\` vazio — erro engolido (piso comum: erro nunca é engolido)")
  grep -qE 'catch\s*\{\s*print\(' <<< "$codigo" && avisos+=("$nome: \`catch { print(...) }\` — print não é tratamento nem log estruturado")

  # 3. concorrência
  grep -qE 'DispatchSemaphore' <<< "$codigo" \
    && erros+=("$nome: \`DispatchSemaphore\` — esperar async com semáforo é deadlock na main thread esperando acontecer (piso.md secao 2)")
  grep -qE '@unchecked Sendable' <<< "$codigo" \
    && ! grep -qE '@unchecked Sendable.*//|//.*@unchecked' "$f" \
    && avisos+=("$nome: \`@unchecked Sendable\` sem comentário explicando a invariante que o compilador não vê")

  # 4. memória
  grep -qE '\bunowned\b' <<< "$codigo" \
    && avisos+=("$nome: \`unowned\` — só quando o dono é garantidamente mais longevo; se não for, é crash, não nil")
  grep -qE 'weak var .*delegate' <<< "$codigo" || true

  # 5. segurança do cliente
  grep -qE 'UserDefaults\.standard\.set\([^)]*(token|senha|password|secret|apiKey)' <<< "$codigo" \
    && erros+=("$nome: credencial em \`UserDefaults\` — é um plist EM CLARO; use Keychain")
  grep -qE '(apiKey|api_key|secret|token)\s*(=|:)\s*""' <<< "$(sed 's|//.*$||' "$f")" \
    && grep -qE '(apiKey|api_key|secret|token)\s*(=|:)\s*"[A-Za-z0-9_\-]{12,}"' "$f" \
    && erros+=("$nome: possível segredo literal no código — tudo no .ipa é legível com \`strings\`")
  # No arquivo CRU: a chave aparece como STRING no código ou como <key> no plist — procurá-la no
  # código já sem strings deixaria o gate cego justo onde ela mora.
  grep -qE 'NSAllowsArbitraryLoads' "$f" \
    && erros+=("$nome: \`NSAllowsArbitraryLoads\` — TLS relaxado; VETADO fora de teste local documentado")

  # 6. rede sem timeout
  grep -qE 'URLSessionConfiguration\.default' <<< "$codigo" \
    && ! grep -qE 'timeoutInterval' "$f" \
    && avisos+=("$nome: URLSession sem \`timeoutInterval\` explícito")
done

# Info.plist é onde a chave de TLS relaxado mora de verdade.
while IFS= read -r -d '' plist; do
  grep -q 'NSAllowsArbitraryLoads' "$plist" \
    && erros+=("${plist#"$raiz"/}: NSAllowsArbitraryLoads no Info.plist — TLS relaxado no app inteiro")
done < <(find "$raiz" -type f -name '*.plist' -not -path '*/.build/*' -not -path '*/.git/*' -print0 2>/dev/null)

for a in "${avisos[@]:-}"; do [ -n "$a" ] && echo "  ! $a" >&2; done
if [ "${#erros[@]}" -gt 0 ]; then
  echo "" >&2
  echo "✖ SWIFT REPROVADO — ${#erros[@]} problema(s) em ${#arquivos[@]} arquivo(s):" >&2
  for e in "${erros[@]}"; do echo "  · $e" >&2; done
  exit 1
fi
echo "✔ swift: ${#arquivos[@]} arquivo(s) nas regras textuais do piso$(command -v swift >/dev/null 2>&1 && echo '' || echo ' — SEM toolchain nesta máquina: o compilador é quem manda de verdade')."
