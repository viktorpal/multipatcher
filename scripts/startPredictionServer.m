confModel = Config.createFromXml(fullfile('config', 'prediction_config.xml'));
networkModel = confModel.prediction.networkModel;
networkWeights = confModel.prediction.networkWeights;
net = caffe.Net(networkModel, networkWeights, 'test');

if confModel.prediction.use_gpu
    caffe.set_mode_gpu;
else
    caffe.set_mode_cpu;
end

s = RemoteWorker.Server();
registerCommand(s, 'predict', @(header,data) predictImage(net,data))
s.run();

function probability = predictImage(net, data)
    input_data = data;
    input_data = cat(3,input_data,input_data,input_data);
    res = net.forward({input_data});
    probability = res{1};
end