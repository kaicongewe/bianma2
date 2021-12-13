input =randi([0,1],1,2000);
samplerate=8000;
n=0.5;
[output,snr,ber] = channel(input,samplerate,n);


function [output,snr,ber]= channel(input,samplerate,noisepower)
    %pre-processing
    len=length(input);
    if mod(len,4)~=0
        input=[input,zeros(1,mod(len,4))];
    end
    
    %modulation using 16qam
    modded = qammod(input',16,'InputType','bit');

    %pulse shaping raised cosine filter
    Datarate=len/5;%have to transmit in 5s
    span=6;
    sampspersym=samplerate/Datarate;
    txfilter = comm.RaisedCosineTransmitFilter('RolloffFactor',0.5, ...
    'FilterSpanInSymbols',span,'OutputSamplesPerSymbol',sampspersym);
    
    filterdelay=4*span;
    err=comm.ErrorRate('ReceiveDelay',filterdelay);
    transmit=txfilter(modded);

    %transmitted waveform
    t = 0:((1/Datarate)/1000):(1/Datarate);
    TxSig = [];
    for l=1:len
        Tx = real(transmit(l))*cos(2*pi*Datarate*t) - imag(transmit(l))*sin(2*pi*Datarate*t); 
        TxSig = [TxSig Tx]; 
    end
    figure
    subplot(2,2,1)
    plot(TxSig); title('Transmitted Signal Waveform'); 
    xlim([0,len*Datarate+len]);
    ylim([-2 2])

    %calculate SNR
    signalpower=bandpower(modded);
    snr=signalpower/noisepower+10*log10(4)-10*log10(sampspersym);

    %receive the signal
    receive=awgn(transmit,snr,'measured');
    RxSig=awgn(TxSig,snr,'measured');
    subplot(2,2,3)
    plot(RxSig); title('Received Signal Waveform');
    xlim([0,len*Datarate+len]);
    ylim([-2 2])

    %matched filtering raised cosine filter
    rxfilter = comm.RaisedCosineReceiveFilter('RolloffFactor',0.5, ...
    'FilterSpanInSymbols',span,'InputSamplesPerSymbol',sampspersym, ...
    'DecimationFactor',sampspersym);
    receivefiltered=rxfilter(receive);
    output = qamdemod(receivefiltered,16,'OutputType','bit')';
    
    %PSDs
    T=16/samplerate;
    dt=1/(sampspersym*samplerate);
    t=-T/2:dt:T/2-dt;
    [f1,tmp1]=t2f(t,transmit);
    [f2,tmp2]=t2f(t,receive);
    PSDTx=10*log10(tmp1);
    PSDRx=10*log10(tmp2);
    PSDTx=abs(PSDTx).^2;
    PSDRx=abs(PSDRx).^2;
    subplot(2,2,2)
    plot(f1,PSDTx);title('Transmitted Signal Spectral Density'); 
    subplot(2,2,4)
    plot(f2,PSDRx);title('Received Signal Spectral Density'); 

    %error analysis
    error=err(input',output');
    ber=error(1);
end

function [f,sf]= t2f(t,st) 
    dt = t(2)-t(1); T=t(end); df = 1/(10*dt); 
    N = length(st); f=-N/2*df : df : N/2*df-df; 
    sf = fft(st); sf = T/N*fftshift(sf); 
end