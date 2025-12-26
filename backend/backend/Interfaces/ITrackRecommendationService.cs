namespace backend.Interfaces
{
    public interface ITrackRecommendationService
    {
        Task<List<string>> GetSimilarTrackIdsAsync(List<string> recentTrackIds, int topK = 20);
    }
}

