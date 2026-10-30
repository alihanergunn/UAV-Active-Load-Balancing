
function [SwitchCmd, FDI] = IntelligentLoadBalancing(Iphase, Iload, Enable, Reset, t)

% Iphase: 3x1 faz RMS akimlari [A; B; C]
% Iload:  9x1 yuk RMS akimlari
% Enable: algoritma etkinlestirme girisi
% Reset:  baslangic/reset girisi
% t:      Clock blogundan gelen zaman (s)
% SwitchCmd: 27x1 anahtar komutlari
% FDI: faz dengesizlik indeksi (%)

StartDelay = 0.35;
MoveDelay  = 0.1;
FDI_Start  = 5.0;
FDI_Stop   = 3.0;

persistent LoadPhase LastMoveTime Balancing

% Baslangic dagilimi: 1=A, 2=B, 3=C
if isempty(LoadPhase) || Reset ~= 0
    LoadPhase = [1; 2; 1; 3; 2; 1; 3; 2; 3];
    LastMoveTime = -1e6;
    Balancing = false;
end

% FDI hesapla
Iavg = mean(Iphase);

if Iavg > 0
    FDI = max(abs(Iphase - Iavg)) / Iavg * 100;
else
    FDI = 0;
end

% Mevcut dagilima gore anahtarlari olustur
SwitchCmd = zeros(27,1);

for k = 1:9
    idx = (k-1)*3 + LoadPhase(k);
    SwitchCmd(idx) = 1;
end

% Reset aktifse mevcut baslangic komutlarini ver
if Reset ~= 0
    return;
end

% Enable kapaliysa aktarim yapma
if Enable == 0
    return;
end

% Baslangicta 0.35 saniye bekle
if t < StartDelay
    return;
end

% FDI histerezisi
if FDI > FDI_Start
    Balancing = true;
elseif FDI <= FDI_Stop
    Balancing = false;
end

% Dengeleme gerekmiyorsa cik
if ~Balancing
    return;
end

% Aktarimlar arasinda 100 ms bekle
if (t - LastMoveTime) < MoveDelay
    return;
end

% En yuklu ve en az yuklu fazlari bul
[~, SourcePhase] = max(Iphase);
[~, TargetPhase] = min(Iphase);

% En yuklu fazdaki en kucuk akimli yuku bul
SelectedLoad = 0;
SmallestCurrent = inf;

for k = 1:9
    if LoadPhase(k) == SourcePhase && Iload(k) < SmallestCurrent
        SmallestCurrent = Iload(k);
        SelectedLoad = k;
    end
end

% Kaynak fazda uygun yuk yoksa aktarim yapma
if SelectedLoad == 0
    return;
end

% Secilen yuku hedef faza aktar
LoadPhase(SelectedLoad) = TargetPhase;
LastMoveTime = t;

% Yeni anahtar komutlarini olustur
SwitchCmd = zeros(27,1);

for k = 1:9
    idx = (k-1)*3 + LoadPhase(k);
    SwitchCmd(idx) = 1;
end

end
