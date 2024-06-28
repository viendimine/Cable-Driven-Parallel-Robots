clear all
close all
clc

Ts = 1e-4;                      %Sample Time [s]
z = tf('z',Ts);

%Desired Trajectory
M = 1000;                       %M+1: Number of discrete trajectory points
y_d = [0:1:M]'*Ts;              %Desired trajectory: straight line [m]

%System Parameters
p = 0.5;            
a = -1.1;
G = (z-a)/(z-p);
Gvec = impulse(G,[0:1:M]'*Ts);
Gvec = Gvec*dcgain(G)/sum(Gvec);
Gm = toeplitz(Gvec,[Gvec(1); zeros(M,1)]);  %LSR

%B-splines
M = 1000;                       %M+1: Number of discrete trajectory points
m = 5;                          %Degree of B-splines
n = 100;                        %n+1: number of B-splines
g = linspace(0,1,M+1);                      
knot0 = linspace(0,1,n-m+2); 
I = ones(1,m);

U = [0*I knot0 I]; 
s = findspan (n, m, g, U);
N1 = basisfun (s, g, m, U);

N = zeros(length(g),n+1);
ic = s(1);
for i = 1:length(g)
   coml = s(i)-ic+1;
   N(i,coml:coml+m) = N1(i,:);   %N: Basis function matrix            
end

%Filtering
Nt = Gm*N;                      %Filtered Basis Functions
gamma = pinv(Nt)*y_d;           %Coefficients
u = N*gamma;                    %Control Input 
y = Gm*u;                       %Output FBF
y1 = Gm*y_d;                    %Output Uncompensated

t = [0:1:M]'*Ts;                    %Time [s]


figure
semilogy(t,abs(y_d-y)*1e3,'r','Linewidth',2);
hold on
semilogy(t,abs(y_d-y1)*1e3,'k--','Linewidth',2);
grid on
xlabel('Time [s]');
ylabel('Absolute Error [mm]');
legend('FBF','Uncompensated');

%Pulse Basis functions
 U1 = zeros(M+1,n+1);
 q = floor((E+1)/(n+1));
 
 for i=0:1:n-1
     for k=0:1:M
     if k>=(i)*(M)/(n+1) && k<(i+1)*(M)/(n+1)
         U1(k+1,i+1) = 1;
     else
         U1(k+1,i+1) = 0;
     end
     end
 end
 for i=n
     for k=0:1:M
     if k>=(i)*(M)/(n+1) && k<=(i+1)*(M)/(n+1)
         U1(k+1,i+1) = 1;
     else
         U1(k+1,i+1) = 0;
     end
     end
 end
 U_BPF = U1;

%DCT Basis functions
 U2 = zeros(M+1,n+1);
 j = 1:2:2*M+1;
 for i=0:1:n
     if i == 0
         U2(:,i+1) = cos(pi*i*j/2/(M+1))/sqrt(M+1);
     else
         U2(:,i+1) = sqrt(2)*cos(pi*i*j/2/(M+1))/sqrt(M+1);
     end
 end
 U_DCT = U2;