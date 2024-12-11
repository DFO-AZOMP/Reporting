
clear
pack

ID=[15;16;17;18;19;20];

PS(7,1:4)=[0.05 0.96 0.8 0.03];

PS(1,1:4)=[0.69 0.50 0.2 0.45];
PS(2,1:4)=[0.37 0.50 0.2 0.45];
PS(3,1:4)=[0.05 0.50 0.2 0.45];
PS(4,1:4)=[0.69 0.05 0.2 0.45];
PS(5,1:4)=[0.37 0.05 0.2 0.45];
PS(6,1:4)=[0.05 0.05 0.2 0.45];



year1=1993;year2=2023;

dp=zeros(length(ID),year2-year1+1);

for year=year1:year2
    
    figure(year-year1+1)
    axes('position',PS(7,:));
    text(0.5,0.05,num2str(year),'fontsize',12,'fontweight','bold');
    axis off
x0=0;
y0=0;
width=21;
height=29
set(gcf,'units','centimeters','position',[x0,y0,width,height])

    for station=1:length(ID)
        
        filename=['./',num2str(year),'/',num2str(year),'_AR7W',num2str(ID(station)),'.mat']
        
        A=isfile(filename)      
        if A==0
            dp(station,year-year1+1)=nan;
            axes('position',PS(station,:));
        else
            load(filename);
            if max(P.depth)<=500
                dp(station,year-year1+1)=nan;
                axes('position',PS(station,:));
                plot(P.T,-P.depth,'r-');
                
            else
                dp(station,year-year1+1)=ra_mld(P.S(400:end),P.T(400:end),P.depth(400:end),0.3);
                axes('position',PS(station,:));
                plot(P.T,-P.depth,'r-');

            end
        end
    end   
    %print([num2str(year),'.jpg'],'-djpeg','-r300');
    
end

load /media//data/wangz/North_Atlantic/NA6/NA6_run3_Iforcing_SmallSM/Convection_depths.mat
load /media//data/wangz/North_Atlantic/NA6/NA6_run3_Iforcing_SmallSM/convetion_depth_2016_2023.mat
for n=1:(year2-year1+1)
   tmp=squeeze(dp(:,n));
    convect(n)=nanmean(tmp(:));
    %Cstd(n)=nanstd(tmp(:));
    Cstd(n)=0;
end
figure
errorbar([1993:2023],-convect,Cstd);grid on
hold on
plot([1990:2015],-OBS_depth,'o')
plot([2016:2023],-depth,'o')

