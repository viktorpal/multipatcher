originalPosition = pip.getPosition();

pip.moveTo(drawbackPosition(1), [], [], 'speed', 'fast');
pip.waitForFinished();
pip.moveTo([], alconoxPosition(2), alconoxPosition(3), 'speed', 'fast');
pip.waitForFinished();
pip.moveTo(alconoxPosition(1), [], [], 'speed', 'fast');
pip.waitForFinished();

for i = 1:1
    model.autopatcher.pressureController.setPressure(1000);
    while model.autopatcher.pressureController.getPressure() < 900
        pause(1);
    end
    pause(1);
    model.autopatcher.pressureController.setPressure(0);
    pause(1);
    model.autopatcher.pressureController.setPressure(-300);
    while model.autopatcher.pressureController.getPressure() > -300
        pause(1);
    end
    pause(4);
    model.autopatcher.pressureController.setPressure(0);
    pause(1);
end
model.autopatcher.pressureController.setPressure(1000);
while model.autopatcher.pressureController.getPressure() < 900
    pause(1);
end
pause(1);
model.autopatcher.pressureController.setPressure(20);
pause(1);

pip.moveTo(drawbackPosition(1), [], [], 'speed', 'fast');
pip.waitForFinished();
pip.moveTo([], acsfPosition(2), acsfPosition(3), 'speed', 'fast');
pip.waitForFinished();
pip.moveTo(acsfPosition(1), [], [], 'speed', 'fast');
pip.waitForFinished();

model.autopatcher.pressureController.setPressure(1000);
while model.autopatcher.pressureController.getPressure() < 900
    pause(0.5);
end
pause(10);
model.autopatcher.pressureController.setPressure(0);
pause(1);

pip.moveTo(drawbackPosition(1), [], [], 'speed', 'fast');
pip.waitForFinished();
pip.moveTo([], originalPosition(2), originalPosition(3), 'speed', 'fast');
pip.waitForFinished();
pip.moveTo(originalPosition(1), [], [], 'speed', 'fast');
pip.waitForFinished();


