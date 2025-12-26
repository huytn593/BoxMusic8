using backend.Interfaces;
using backend.Models;

namespace backend.Services;

public class TrackRecommendationService : ITrackRecommendationService
{
    private readonly ITrackRepository _trackRepo;

    public TrackRecommendationService(ITrackRepository trackRepo)
    {
        _trackRepo = trackRepo;
    }

    public async Task<List<string>> GetSimilarTrackIdsAsync(List<string> recentTrackIds, int topK = 20)
    {
        if (recentTrackIds == null || recentTrackIds.Count == 0) return new List<string>();

        var seedTracks = await _trackRepo.GetEmbedding(recentTrackIds);
        var seedEmbeddings = seedTracks
            .Where(t => t.Embedding != null)
            .Select(t => t.Embedding)
            .ToList();

        if (seedEmbeddings.Count == 0) return new List<string>();

        int dim = seedEmbeddings[0].Length;
        float[] centroid = new float[dim];

        foreach (var emb in seedEmbeddings)
            for (int i = 0; i < dim; i++)
                centroid[i] += emb[i];

        for (int i = 0; i < dim; i++)
            centroid[i] /= seedEmbeddings.Count;

        var allTracks = await _trackRepo.GetAllValidWithEmbedding();

        var similarTracks = allTracks
            .Where(t => !recentTrackIds.Contains(t.Id))
            .Select(t => new
            {
                Id = t.Id,
                Distance = CosineDistance(centroid, t.Embedding!)
            })
            .OrderBy(t => t.Distance)
            .Take(topK)
            .Select(t => t.Id)
            .ToList();

        return similarTracks;
    }

    private double CosineDistance(float[] vec1, float[] vec2)
    {
        double dot = 0, norm1 = 0, norm2 = 0;
        for (int i = 0; i < vec1.Length; i++)
        {
            dot += vec1[i] * vec2[i];
            norm1 += vec1[i] * vec1[i];
            norm2 += vec2[i] * vec2[i];
        }

        if (norm1 == 0 || norm2 == 0) return 1;
        return 1 - (dot / (Math.Sqrt(norm1) * Math.Sqrt(norm2)));
    }
}
