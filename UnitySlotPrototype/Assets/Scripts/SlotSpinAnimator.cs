using System.Collections;
using UnityEngine;

public class SlotSpinAnimator : MonoBehaviour
{
    [SerializeField] private Transform[] reelTransforms;
    [SerializeField] private float spinDistance = 2.5f;
    [SerializeField] private float spinDuration = 1.2f;
    [SerializeField] private AnimationCurve spinEase = AnimationCurve.EaseInOut(0f, 0f, 1f, 1f);

    private Vector3[] startPositions;
    private bool initialized;

    private void Awake()
    {
        CachePositions();
    }

    private void CachePositions()
    {
        if (reelTransforms == null)
        {
            return;
        }

        startPositions = new Vector3[reelTransforms.Length];
        for (int i = 0; i < reelTransforms.Length; i++)
        {
            if (reelTransforms[i] != null)
            {
                startPositions[i] = reelTransforms[i].localPosition;
            }
        }
        initialized = true;
    }

    public void PlaySpin()
    {
        if (!initialized)
        {
            CachePositions();
        }

        StopAllCoroutines();
        StartCoroutine(SpinRoutine());
    }

    private IEnumerator SpinRoutine()
    {
        float elapsed = 0f;
        while (elapsed < spinDuration)
        {
            float t = Mathf.Clamp01(elapsed / spinDuration);
            float eased = spinEase.Evaluate(t);
            float offset = Mathf.Lerp(0f, spinDistance, eased);

            for (int i = 0; i < reelTransforms.Length; i++)
            {
                if (reelTransforms[i] == null)
                {
                    continue;
                }

                float stagger = i * 0.05f;
                float staggered = Mathf.Clamp01(t + stagger);
                float localOffset = Mathf.Lerp(0f, spinDistance, spinEase.Evaluate(staggered));
                reelTransforms[i].localPosition = startPositions[i] + Vector3.down * localOffset;
            }

            elapsed += Time.deltaTime;
            yield return null;
        }

        for (int i = 0; i < reelTransforms.Length; i++)
        {
            if (reelTransforms[i] != null)
            {
                reelTransforms[i].localPosition = startPositions[i];
            }
        }
    }
}
