# Publica uma nova versão do SWX2 no GitHub (Swairovsk-dev/SWX2).
# Quem já tem o SWX2 recebe o aviso de atualização ao abrir o programa.
#
# Uso:  .\publicar.ps1 -Notas "o que mudou"
#       .\publicar.ps1 -Notas "..." -Versao 1.2.0   (escolhe a versão em vez de somar 1)
param(
  [string]$Notas = 'Melhorias e correções.',
  [string]$Versao = '',
  [string]$Fonte = 'C:\Users\dougl\Documents\GitHub\pcsx2'
)
$ErrorActionPreference = 'Stop'
$app = $PSScriptRoot
Set-Location $app

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
}
Set-Content (Join-Path $app 'versao.txt') $Versao -NoNewline -Encoding ascii

# 3. Monta o zip só com os arquivos do programa (nunca dados, jogos, bios ou saves).
$stage = Join-Path $env:TEMP 'swx2-release'
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
robocopy $app $stage /E /NFL /NDL /NJH /NJS `
  /XD (Join-Path $app '.git') (Join-Path $app 'dados') (Join-Path $app 'jogos') (Join-Path $app 'bios') (Join-Path $app 'source') (Join-Path $app 'state') `
  /XF '*.bak' 'publicar.ps1' '.gitignore' '.gitattributes' 'portable.txt' | Out-Null
if ($LASTEXITCODE -ge 8) { throw "Falha ao montar o pacote ($LASTEXITCODE)" }
$zip = Join-Path $env:TEMP 'SWX2-update.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal
Remove-Item $stage -Recurse -Force

# 4. Envia o código do pacote e cria a release com o zip.
git add -A
git commit -m "SWX2 $tag" -m $Notas
git push
gh release create $tag $zip --title "SWX2 $tag" --notes $Notas
Write-Host "Pronto: $tag publicada."
