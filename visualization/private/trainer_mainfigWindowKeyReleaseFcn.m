function trainer_mainfigWindowKeyReleaseFcn( ~, eventdata, trainerHandles )
%TRAINER_MAINFIGKEYPRESSFCN 

if strcmp('delete', eventdata.Key)
    trainerModel = trainerHandles.mainfigure.UserData;
    trainer_deleteSelectedBox(trainerModel);
elseif strcmp('rightarrow', eventdata.Key)
    trainer_selectNext(trainerHandles)
elseif strcmp('leftarrow', eventdata.Key)
    trainer_selectPrev(trainerHandles)
end

end

