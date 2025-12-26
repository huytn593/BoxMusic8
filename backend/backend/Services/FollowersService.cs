using backend.Interfaces;
using backend.Controllers;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;
using backend.DTOs;

namespace backend.Services
{
    public class FollowersService : IFollowersService
    {
        private readonly IFollowersRepository _followersRepository;
        private readonly IUsersService _usersService;
        private readonly IUserRepository _usersRepository;
        public FollowersService(IFollowersRepository followersRepository, IUsersService usersService, IUserRepository usersRepository)
        {
            _followersRepository = followersRepository;
            _usersService = usersService;
            _usersRepository = usersRepository;
        }        

        public async Task FollowAsync(string followerId, string followingId)
        {
            await _usersService.UpdateFollowCount(followerId, 1);
            await _followersRepository.FollowAsync(followerId, followingId);
        }

        public async Task UnfollowAsync(string followerId, string followingId)
        {
            await _usersService.UpdateFollowCount(followerId, -1);
            await _followersRepository.UnfollowAsync(followerId, followingId);
        }

        public async Task<bool> IsFollowingAsync(string followerId, string followingId)
        {
            return await _followersRepository.IsFollowingAsync(followerId, followingId);
        }

        public async Task<List<string>> GetFollowingListAsync(string followerId)
        {
            return await _followersRepository.GetFollowingListAsync(followerId);
        }

        public async Task<List<FollowingDetailsResponse>> GetFollowingDetailsListAsync(string followerId)
        {
            var followingIds = await _followersRepository.GetFollowingListAsync(followerId);
            var followingDetails = new List<FollowingDetailsResponse>();

            foreach (var followingId in followingIds)
            {
                var user = await _usersRepository.GetByIdAsync(followingId);
                if (user != null)
                {
                    string? avatarBase64 = !string.IsNullOrEmpty(user.AvatarUrl)
                        ? $"http://localhost:5270/avatar/{user.AvatarUrl}"
                        : null;

                    followingDetails.Add(new FollowingDetailsResponse
                    {
                        FollowingId = user.Id,
                        FollowingName = user.Name,
                        FollowingEmail = user.Email,
                        FollowingAvatar = avatarBase64,
                        FollowingRole = user.Role,
                        FollowingGender = user.Gender,
                        FollowingDateOfBirth = user.DateOfBirth,
                        IsFollowing = true
                    });
                }
            }

            return followingDetails;
        }
    }
} 