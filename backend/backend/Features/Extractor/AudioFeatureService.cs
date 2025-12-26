using NAudio.Wave;
using NWaves.FeatureExtractors;
using NWaves.FeatureExtractors.Options;
using NWaves.Signals;

namespace backend.Features.Extractor;

public class AudioFeatureService
{
    public float[] ExtractFeatures(string filePath)
    {
        using var mp3Reader = new Mp3FileReader(filePath);
        using var pcmStream = WaveFormatConversionStream.CreatePcmStream(mp3Reader);
        var waveProvider = new Wave16ToFloatProvider(pcmStream); // KHÔNG using

        int sampleRate = waveProvider.WaveFormat.SampleRate;
        int channels = waveProvider.WaveFormat.Channels;

        int secondsToRead = 10;
        int totalSamples = sampleRate * secondsToRead * channels;

        var bytes = new byte[totalSamples * sizeof(float)];
        int bytesRead = waveProvider.Read(bytes, 0, bytes.Length);

        int floatsRead = bytesRead / sizeof(float);
        var samples = new float[floatsRead];
        Buffer.BlockCopy(bytes, 0, samples, 0, bytesRead);

        float[] monoSamples = channels == 2
            ? ToMono(samples, floatsRead)
            : samples.Take(floatsRead).ToArray();

        var signal = new DiscreteSignal(sampleRate, monoSamples);

        var options = new MfccOptions
        {
            SamplingRate = sampleRate,
            FeatureCount = 13,
            FrameDuration = 0.025,
            HopDuration = 0.01
        };

        var extractor = new MfccExtractor(options);
        var mfccs = extractor.ComputeFrom(signal);

        var meanVector = new float[13];
        foreach (var vec in mfccs)
        {
            for (int i = 0; i < vec.Length; i++)
                meanVector[i] += vec[i];
        }

        for (int i = 0; i < meanVector.Length; i++)
            meanVector[i] /= mfccs.Count;

        return meanVector;
    }

    private float[] ToMono(float[] stereoSamples, int length)
    {
        var mono = new float[length / 2];
        for (int i = 0; i < mono.Length; i++)
        {
            mono[i] = (stereoSamples[2 * i] + stereoSamples[2 * i + 1]) / 2f;
        }
        return mono;
    }
}
