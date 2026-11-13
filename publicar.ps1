# Publica uma nova versão do SWX2 no GitHub (Swairovsk-dev/SWX2).
# Quem já tem o SWX2 recebe o aviso de atualização ao abrir o programa.
#
# Uso:  .\publicar.ps1 -Notas "o que mudou"
#       .\publicar.ps1 -Notas "..." -Versao 1.2.0   (escolhe a versão em vez de somar 1)
#
# Fonte: pasta do código do PCSX2 com as alterações do SWX2. Padrão: $env:SWX2_FONTE ou ..\pcsx2.
param(
  [string]$Notas = 'Melhorias e correções.',
  [string]$Versao = '',
  [string]$Fonte = $(if ($env:SWX2_FONTE) { $env:SWX2_FONTE } else { Join-Path (Split-Path $PSScriptRoot -Parent) 'pcsx2' })
)
$ErrorActionPreference = 'Stop'
$app = $PSScriptRoot
Set-Location $app

# 0. Confere o login no gh antes de mexer em versão, zip ou commit.
$ErrorActionPreference = 'Continue'
gh auth status *> $null
$logado = $LASTEXITCODE -eq 0
$ErrorActionPreference = 'Stop'
if (-not $logado) { throw 'gh não está logado. Rode: gh auth login' }

# A GPL pede o código-fonte correspondente a cada binário publicado: sem a pasta do código, não publica.
if (-not (Test-Path "$Fonte\bin\SWX2.exe")) { throw "Build não encontrado em $Fonte\bin\SWX2.exe (use -Fonte ou SWX2_FONTE)." }

# 1. Nova versão: soma 1 no último número, a menos que -Versao seja dado.
$atual = (Get-Content (Join-Path $app 'versao.txt') -Raw).Trim()
if (-not $Versao) {
  $p = $atual.Split('.') | ForEach-Object { [int]$_ }
  $Versao = '{0}.{1}.{2}' -f $p[0], $p[1], ($p[2] + 1)
}
$tag = "v$Versao"
Write-Host "Publicando $tag (antes: $atual)"

# 2. O exe precisa ser mais novo que o código: senão a release sairia sem as últimas alterações.
$exeTime = (Get-Item "$Fonte\bin\SWX2.exe").LastWriteTime
$pastas = 'pcsx2-qt', 'pcsx2', 'common', 'tools\swx2', '3rdparty\discord-rpc' | ForEach-Object { Join-Path $Fonte $_ } | Where-Object { Test-Path $_ }
$maisNovos = Get-ChildItem $pastas -Recurse -File -Include *.cpp, *.h, *.inl, *.ui, *.qrc, *.rc, *.vcxproj |
  Where-Object { $_.LastWriteTime -gt $exeTime }
if ($maisNovos) {
  $maisNovos | Select-Object -First 10 | ForEach-Object { Write-Host "  mais novo que o exe: $($_.FullName)" }
  throw 'O código foi alterado depois do último build. Compile o SWX2.exe de novo antes de publicar.'
}

# 3. Gera o patch com TODAS as alterações sobre o commit do PCSX2 (inclusive arquivos novos).
#    Usa um índice temporário para não mexer no índice do repositório do código.
$base = (git -C $Fonte rev-parse HEAD).Trim()
$patch = Join-Path $app 'source\swx2-frontend.patch'
$indice = Join-Path $env:TEMP 'swx2-patch.index'
$indiceAtual = (git -C $Fonte rev-parse --git-path index).Trim()
if (-not [IO.Path]::IsPathRooted($indiceAtual)) { $indiceAtual = Join-Path $Fonte $indiceAtual }
Copy-Item $indiceAtual $indice -Force
$env:GIT_INDEX_FILE = $indice
$ErrorActionPreference = 'Continue'   # avisos de LF/CRLF do git vão para o stderr
try {
  git -C $Fonte add -A
  if ($LASTEXITCODE -ne 0) { throw 'git add no código falhou' }
  # --output evita a conversão de codificação do redirecionamento do PowerShell 5.1.
  git -C $Fonte diff --cached --binary HEAD "--output=$patch"
  if ($LASTEXITCODE -ne 0) { throw 'Falha ao gerar o patch' }
} finally {
  $ErrorActionPreference = 'Stop'
  Remove-Item Env:GIT_INDEX_FILE
  Remove-Item $indice -Force -ErrorAction SilentlyContinue
}
Set-Content (Join-Path $app 'source\BASE_COMMIT.txt') $base -NoNewline -Encoding ascii
Write-Host ("Patch: {0:N0} KB sobre PCSX2 {1}" -f ((Get-Item $patch).Length / 1KB), $base.Substring(0, 10))

# 4. Traz o build e os recursos.
Copy-Item "$Fonte\bin\SWX2.exe" $app -Force
robocopy "$Fonte\bin\resources" "$app\resources" /E /NFL /NDL /NJH /NJS | Out-Null
if ($LASTEXITCODE -ge 8) { throw "Falha ao copiar resources ($LASTEXITCODE)" }
$Notas += "`n`nCódigo-fonte: PCSX2 $base + source/swx2-frontend.patch"

# Daqui até o commit, uma falha devolve o versao.txt ao valor anterior.
Set-Content (Join-Path $app 'versao.txt') $Versao -NoNewline -Encoding ascii
try {
  # 5. Monta o zip só com os arquivos do programa (nunca dados, jogos, bios ou saves).
  $stage = Join-Path $env:TEMP 'swx2-release'
  if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
  robocopy $app $stage /E /NFL /NDL /NJH /NJS `
    /XD (Join-Path $app '.git') (Join-Path $app 'dados') (Join-Path $app 'jogos') (Join-Path $app 'bios') (Join-Path $app 'source') (Join-Path $app 'state') (Join-Path $app 'painel') `
    /XF '*.bak' '*.old' 'publicar.ps1' '.gitignore' '.gitattributes' 'portable.txt' 'atualizacao-antigos.txt' | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "Falha ao montar o pacote ($LASTEXITCODE)" }
  $zip = Join-Path $env:TEMP 'SWX2-update.zip'
  if (Test-Path $zip) { Remove-Item $zip -Force }
  Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal
  Remove-Item $stage -Recurse -Force
  # O SWX2 só instala a atualização se o SHA-256 do zip baixado bater com este arquivo.
  $sha = "$zip.sha256"
  (Get-FileHash $zip -Algorithm SHA256).Hash | Set-Content $sha -NoNewline -Encoding ascii

  # 6. Envia o código do pacote.
  #    git e gh escrevem progresso no stderr; o resultado vem do código de saída.
  $ErrorActionPreference = 'Continue'
  # Windows PowerShell 5.1 drops embedded double quotes when passing arguments to git/gh.
  $Notas = $Notas -replace '"', '\"'
  # dados/ fica de fora: são as configurações e capas desta máquina, não do pacote.
  git add -A -- . ':(exclude)dados'
  git commit -m "SWX2 $tag" -m $Notas
  if ($LASTEXITCODE -ne 0) { throw "git commit falhou ($LASTEXITCODE)" }
} catch {
  Set-Content (Join-Path $app 'versao.txt') $atual -NoNewline -Encoding ascii
  throw
}

git push 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { throw "git push falhou ($LASTEXITCODE). O commit local já existe: rode git push e depois o gh release create." }
gh release create $tag $zip $sha --title "SWX2 $tag" --notes $Notas
if ($LASTEXITCODE -ne 0) { throw "gh release falhou ($LASTEXITCODE)" }
Write-Host "Pronto: $tag publicada."
