clear, close, clc;

%1/2 eff. Poly(15,17)oct.=>(1101, 1111)=>(2,1,4)code
%1/3 eff. Poly(13,15,17)oct.=>(1011, 1101, 1111)=>(3,1,4)code
code = [1 0 1 1 0 1];
A = [1 0 1 1; 1 0 1 0];

encoded = conv_encode(code, A);
recovered = conv_decode(output1, A, 'hard');

simga = 0.5;
encode_noisy = encoded + rand(1,length(encoded))*sigma;
recover_soft = conv_decode(encode_noisy, A, 'soft');