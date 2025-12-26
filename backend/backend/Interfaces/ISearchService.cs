using backend.DTOs;

namespace backend.Interfaces
{
    public interface ISearchService
    {
        Task<SearchResultDto> SearchAsync(string query);
    }
}

