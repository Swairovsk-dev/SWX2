# Publica uma nova versão do SWX2 no GitHub (Swairovsk-dev/SWX2).
# Quem já tem o SWX2 recebe o aviso de atualização ao abrir o programa.
#
# Uso:  .\publicar.ps1 -Notas "o que mudou"
#       .\publicar.ps1 -Notas "..." -Versao 1.2.0   (escolhe a versão em vez de somar 1)
param(
  [string]$Notas = 'Melhorias e correções.',
  [string]$Versao = '',
  [string]$Fonte = $(if ($env:SWX2_FONTE) { $env:SWX2_FONTE } else { 'C:\Users\dougl\Documents\GitHub\pcsx2' })
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

# 1. Nova versão: soma 1 no último número, a menos que -Versao seja dado.
$atual = (Get-Content (Join-Path $app 'versao.txt') -Raw).Trim()
if (-not $Versao) {
  $p = $atual.Split('.') | ForEach-Object { [int]$_ }
  $Versao = '{0}.{1}.{2}' -f $p[0], $p[1], ($p[2] + 1)
}
$tag = "v$Versao"
Write-Host "Publicando $tag (antes: $atual)"

# 2. Traz o build mais recente do código-fonte, se existir.
if (Test-Path "$Fonte\bin\SWX2.exe") {
  Copy-Item "$Fonte\bin\SWX2.exe" $app -Force
  robocopy "$Fonte\bin\resources" "$app\resources" /E /NFL /NDL /NJH /NJS | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "Falha ao copiar resources ($LASTEXITCODE)" }

  # Registra de qual commit do PCSX2 veio o build (a GPL pede o fonte correspondente).
  $commit = (git -C $Fonte rev-parse --short HEAD).Trim()
  if (git -C $Fonte status --porcelain) { $commit += ' + alterações locais (source/swx2-frontend.patch)' }
  $Notas += "`n`nCódigo-fonte: PCSX2 $commit"
}
Set-Content (Join-Path $app 'versao.txt') $Versao -NoNewline -Encoding ascii

# 3. Monta o zip só com os arquivos do programa (nunca dados, jogos, bios ou saves).
$stage = Join-Path $env:TEMP 'swx2-release'
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
robocopy $app $stage /E /NFL /NDL /NJH /NJS `
  /XD (Join-Path $app '.git') (Join-Path $app 'dados') (Join-Path $app 'jogos') (Join-Path $app 'bios') (Join-Path $app 'source') (Join-Path $app 'state') (Join-Path $app 'painel') `
  /XF '*.bak' 'publicar.ps1' '.gitignore' '.gitattributes' 'portable.txt' | Out-Null
if ($LASTEXITCODE -ge 8) { throw "Falha ao montar o pacote ($LASTEXITCODE)" }
$zip = Join-Path $env:TEMP 'SWX2-update.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal
Remove-Item $stage -Recurse -Force
# O SWX2 só instala a atualização se o SHA-256 do zip baixado bater com este arquivo.
$sha = "$zip.sha256"
(Get-FileHash $zip -Algorithm SHA256).Hash | Set-Content $sha -NoNewline -Encoding ascii

# 4. Envia o código do pacote e cria a release com o zip.
#    git e gh escrevem progresso no stderr; o resultado vem do código de saída.
$ErrorActionPreference = 'Continue'
# Windows PowerShell 5.1 drops embedded double quotes when passing arguments to git/gh.
$Notas = $Notas -replace '"', '\"'
# dados/ fica de fora: são as configurações e capas desta máquina, não do pacote.
git add -A -- . ':(exclude)dados'
git commit -m "SWX2 $tag" -m $Notas
git push 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { throw "git push falhou ($LASTEXITCODE)" }
gh release create $tag $zip $sha --title "SWX2 $tag" --notes $Notas
if ($LASTEXITCODE -ne 0) { throw "gh release falhou ($LASTEXITCODE)" }
Write-Host "Pronto: $tag publicada."
