# Código da interface SWX2

A interface é nativa: **C++ / Qt 6 Widgets / QSS**. O motor de emulação e os formatos de configuração continuam sendo os do PCSX2.

## Liquid Glass

O launcher usa um fundo escuro com três manchas suaves: a cor extraída da capa selecionada, a cor de destaque e um azul profundo. A transição de aproximadamente 600 ms mistura imagens já renderizadas; o desfoque não é recalculado durante cada quadro da animação.

`pcsx2-qt/LiquidGlass.h` contém o material reutilizável, o renderizador do fundo, o blur separável em cache e o controle de contraste. A sidebar, as barras, os cards e o painel de detalhes compartilham esse material. A capa do painel permanece inteira, vertical e sem desfoque.

Os valores do material ficam em `resources/styles/liquid-glass.json`; as regras dos controles ficam em `resources/styles/swx2.qss`. O tema escolhe Inter e Space Grotesk quando disponíveis e usa fontes de fallback quando necessário. O destaque padrão é roxo; uma cor já escolhida pelo usuário é preservada.

Em **Configurações → Interface → Acessibilidade visual → Reduzir transparência**, os painéis ficam mais opacos e os efeitos de movimento são reduzidos. A preferência global é salva em `UI/SWX2ReduceTransparency`. Há também fallback automático para caches acima do limite definido no tema. Os efeitos do fundo e o hover dos cards são suspensos enquanto a emulação está ativa.

O painel de detalhes usa o índice atual da visualização ativa, sem depender do sinalizador temporário `hasSelection()`. Mudanças de seleção, troca entre grade/lista e reinicializações do modelo atualizam o painel, incluindo a seleção inicial do aplicativo.

O preview lateral não usa rolagem: reserva espaço para título, ações, estatísticas, informações e botões de arquivo, e adapta a altura da capa ao espaço restante. Em janelas baixas, usa espaçamentos menores e reúne serial e tamanho numa linha; a região permanece junto da plataforma. O caminho é resumido visualmente, com o valor completo no tooltip e em “Copiar”. A capa mantém a proporção vertical e é renderizada do arquivo original.

## Fontes e compilação

O arquivo `swx2-frontend.patch` reúne as personalizações do frontend sobre o PCSX2 no commit `f0523f8acb1d3a765ee73b74cffec63093569199`. Inclui o código, os ícones e o tema usados pelo executável deste pacote. Não inclui jogos, BIOS ou saves.

Nesta máquina, o projeto completo está em `C:\Users\dougl\Documents\GitHub\pcsx2`. A pasta `SWX2` contém o aplicativo pronto para uso.

Para reproduzir as alterações em outra cópia do código-base:

1. Prepare o código do PCSX2 no commit indicado, suas dependências e os submódulos.
2. Aplique o patch em uma árvore limpa com `git apply --check caminho/swx2-frontend.patch` e depois `git apply caminho/swx2-frontend.patch`.
3. Use o Visual Studio 2022 com a carga de trabalho C++, o SDK do Windows e as dependências Qt já preparadas em `deps/`.

Na raiz do código-fonte, a compilação utilizada é:

```powershell
$sourceRoot = (Get-Location).Path
$msbuild = 'C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe'
& $msbuild pcsx2-qt\pcsx2-qt.vcxproj /p:Configuration=Release /p:Platform=x64 "/p:SolutionDir=$sourceRoot\" /m:2 /v:minimal /nologo
```

O resultado fica em `bin/SWX2.exe`. Ao atualizar uma instalação, copie também os recursos alterados em `bin/resources/`. Preserve `dados/`, `jogos/` e `bios/` da instalação.

## Organização do redesenho

| Arquivo no código-fonte | Responsabilidade |
| --- | --- |
| `bin/resources/styles/swx2.qss` | Paleta, fontes, bordas, espaçamentos e estados dos controles. |
| `pcsx2-qt/Themes.cpp` | Carregamento do QSS, fontes disponíveis e cor de destaque salva em `UI/SWX2Accent`. |
| `pcsx2-qt/GameList/GameListWidget.cpp` | Sidebar, filtros, cards, detalhes, gaveta e navegação. |
| `pcsx2-qt/GameList/GameListModel.cpp` | Dados reais, tooltips e região dos cards. |
| `pcsx2-qt/MainWindow.cpp` | Integração com as ações e os menus existentes; tamanho inicial do launcher. |
| `pcsx2-qt/Settings/SettingsWindow.cpp` | Cabeçalho, navegação e seções das configurações globais e por jogo. |
| `pcsx2-qt/Settings/GraphicsSettingsWidget.cpp` | Página Essenciais, escalas, switches e velocidade, ligados aos controles existentes. |
| `tools/swx2/LauncherSmoke.h` | Verificações de integração e capturas com dados de teste separados. |

Os arquivos `.ui` originais continuam sendo utilizados. As abas avançadas, o menu de contexto e as ações do core permanecem acessíveis. Durante a emulação em janela, os menus nativos voltam a aparecer.

Favoritos, última execução e tempo jogado usam o armazenamento nativo. A compatibilidade vem do banco de jogos; a interface não atribui status fictícios. As resoluções dos cards são referências: a resolução nativa varia conforme o jogo. O limite de FPS usa o controle de velocidade existente e também afeta a velocidade da emulação.

## Verificação da interface

Use uma pasta de testes com uma cópia das configurações e das capas. `-datapath` cria uma subpasta `PCSX2` dentro do caminho fornecido. Não use seus dados pessoais para a verificação que altera temporariamente favoritos e opções por jogo.

```powershell
$env:QT_QPA_PLATFORM = 'offscreen'
$env:SWX2_UI_CAPTURE = 'C:\teste\biblioteca.png'
$env:SWX2_UI_VERIFY = '1'
.\bin\SWX2.exe -datapath C:\teste\dados
Remove-Item Env:QT_QPA_PLATFORM, Env:SWX2_UI_CAPTURE, Env:SWX2_UI_VERIFY
```

O teste grava capturas da biblioteca, do modo compacto, da gaveta e das configurações, além de um relatório `.checks.json`. Para verificar também a abertura de um jogo, use a plataforma Windows normal, configure uma BIOS válida nos dados de teste e defina `SWX2_UI_BOOT_VERIFY=1`. O teste encerra a emulação sem salvar um estado automático.

Use `SWX2_UI_GLASS_VERIFY=1` no lugar de `SWX2_UI_VERIFY` para verificar o material, a cor extraída das capas, a reutilização do cache, a suspensão dos efeitos e a persistência de “Reduzir transparência”. `SWX2_UI_TOOLBAR_VERIFY=1` verifica alinhamento, seletores com rolagem e largura compacta. Esses testes usam os dados isolados fornecidos em `-datapath`.

`SWX2_UI_PREVIEW_VERIFY=1` verifica todos os jogos da biblioteca de teste nas alturas de janela 540, 720, 900 e 1080. Confere que o conteúdo cabe no viewport, que não há faixa de rolagem, que “Copiar” e “Abrir pasta” ficam visíveis e que a capa continua vertical, sem cortes.

O teste automatizado de interface não substitui a validação com um controle físico. O mapeamento implementado usa direcional/analógico esquerdo, A/× para ativar, B/○ para voltar, Y/△ para detalhes e os botões de ombro para mudar o foco. A navegação do launcher não atua enquanto um jogo está em execução nem durante a captura de bindings.

## Licença

As alterações mantêm os avisos GPL do código-base. Consulte `licencas/GPL.html` e `licencas/ThirdPartyLicenses.html` no pacote e os avisos dos arquivos-fonte.
