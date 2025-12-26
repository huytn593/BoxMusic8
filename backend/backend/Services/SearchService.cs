using backend.Controllers;
using backend.DTOs;
using backend.Interfaces;
using backend.Models;

namespace backend.Services
{
    public class SearchService : ISearchService
    {
        private readonly ITrackRepository _trackRepository;
        private readonly IUserRepository _userRepository;

        public SearchService(ITrackRepository trackRepository, IUserRepository userRepository)
        {
            _trackRepository = trackRepository;
            _userRepository = userRepository;
        }

        public async Task<SearchResultDto> SearchAsync(string query)
        {
            var tracks = await _trackRepository.SearchByTitleOrArtistAsync(query);
            var users = await _userRepository.SearchByUsernameOrNameAsync(query);

            var artistIds = tracks
                .Where(t => !string.IsNullOrEmpty(t.ArtistId))
                .Select(t => t.ArtistId)
                .Distinct()
                .ToList();

            var artists = await _userRepository.GetUsersByIdsAsync(artistIds);
            var artistDict = artists.ToDictionary(u => u.Id, u => u.Name);

            var trackDtos = tracks.Select(track =>
            {
                string? artistName = null;
                if (!string.IsNullOrEmpty(track.ArtistId) &&
                    artistDict.TryGetValue(track.ArtistId, out var name))
                {
                    artistName = name;
                }

                return new TrackSearchDto
                {
                    Id = track.Id,
                    Title = track.Title,
                    ArtistName = artistName,
                    LikeCount = track.LikeCount,
                    PlayCount = track.PlayCount,
                    IsPublic = track.IsPublic,
                    ImageBase64 = !string.IsNullOrEmpty(track.Cover)
                        ? $"http://localhost:5270/cover_images/{track.Cover}"
                        : null,
                    AudioUrl = $"http://localhost:5270/api/Track/audio/{track.Id}"
                };
            }).ToList();

            var userDtoTasks = users.Select(async user =>
            {
                string? avatarBase64 = null;
                if (!string.IsNullOrEmpty(user.AvatarUrl))
                {
                    var fileName = Path.GetFileName(user.AvatarUrl);
                    avatarBase64 = $"http://localhost:5270/avatar/{fileName}";
                }

                return new SearchUserDto
                {
                    id = user.Id,
                    fullname = user.Name,
                    username = user.Username,
                    avatarBase64 = avatarBase64,
                };
            });

            var usersDto = (await Task.WhenAll(userDtoTasks)).ToList();

            return new SearchResultDto
            {
                Tracks = trackDtos,
                Users = usersDto,
            };
        }
    }
}
