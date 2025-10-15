## `pairs()` vs `contrast()`
Great question — `pairs()` and `contrast()` are both functions from the `emmean`s package in R, and while they overlap in functionality, they serve slightly different purposes and give you different levels of control.

### Summary of the Difference

| Function | Purpose | Simpler? | Control | Common Use |
|-----------|----------|----------|----------|-------------|
| `pairs()` | A shortcut to compare all levels of a factor using pairwise comparisons | ✅ Yes | ❌ Less control | Simple pairwise EMM comparisons |
| `contrast()` | A general-purpose function to specify any linear contrast, including pairwise, polynomial, custom, interaction, or complex nested designs | ❌ More verbose | ✅ More control | Custom contrasts, interaction contrasts, complex models |

⸻

🔍 Detailed Comparison

✅ pairs()
 - Default method for pairwise comparisons between levels of a factor
 - Assumes you want all possible pairwise comparisons
 - Operates on a single factor at a time
 - Cleaner syntax for simple cases

Example:

emmeans_obj <- emmeans(model, ~ condition)
pairs(emmeans_obj)

This will compute pairwise differences between all levels of condition.

You can also use it with simple = "factor" if your emmeans object has multiple factors:

pairs(emmeans_obj, simple = "group")


⸻

✅ contrast()
	•	More flexible and powerful: you can specify:
	•	Pairwise
	•	Polynomial
	•	Helmert
	•	Tukey
	•	Interaction contrasts
	•	Custom matrices
	•	Allows:
	•	Multiple factors (interactions)
	•	Complex contrast nesting (by, combine, etc.)
	•	Advanced contrast types (e.g., difference of differences)

Example: pairwise comparisons (equivalent to pairs())

contrast(emmeans_obj, method = "pairwise")

Example: interaction contrasts (difference of differences)

contrast(emmeans_obj, interaction = c("pairwise", "pairwise"))

Example: custom contrasts

my_contrast <- rbind("A vs B+C" = c(1, -0.5, -0.5))
contrast(emmeans_obj, method = my_contrast)


⸻

🧠 Rule of Thumb
	•	Use **pairs()** if you’re doing quick pairwise comparisons and don’t need customization.
	•	Use **contrast()** if you’re:
	•	Comparing simple effects within subgroups
	•	Doing interaction contrasts
	•	Applying custom contrast weights
	•	Controlling for multiple factors using by =, combine =, or adjust =

⸻

✅ Quick Code Comparison

# Simple: get all pairwise differences between levels of condition
pairs(emmeans(model, ~ condition))

# Equivalent using contrast:
contrast(emmeans(model, ~ condition), method = "pairwise")

# Interaction contrasts: e.g., difference in condition effect across groups
contrast(emmeans(model, ~ condition * group),
         interaction = c("pairwise", "pairwise"))


⸻

Let me know if you’d like a visual or LaTeX table version of this comparison!