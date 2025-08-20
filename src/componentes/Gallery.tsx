import '../assets/styles/Gallery.css';
// import { useSelector } from 'react-redux';
// import { type NftTokenId } from '../redux/selectedNftSlice';
// import type { FilterType, SortType, SortOrder } from '../types/filterTypes';
// import { useChainId, useReadContract } from 'wagmi';
// import { yoyoNftAbi, chainsToContractAddress } from '../data/smartContractsData';

const Gallery: React.FC = () => {
    // const currentNftSelected = useSelector(
    //     (state: { selectedExercise: { id: NftTokenId } }) => state.selectedExercise.id
    // );
    //const selectedNft = exercisesCardData.find(ex => ex.id === currentNftSelected);

    //const { nfts, loading, error, progress, refetch, totalMinted, maxSupply } = useNftCollection();

    return (
        <div className="galleryContainer">
            <div className="titleContainer">
                <h1>Get your pass to the future of inner peace and mindful movement</h1>
            </div>
            <div></div>
        </div>
    );
};

export default Gallery;
