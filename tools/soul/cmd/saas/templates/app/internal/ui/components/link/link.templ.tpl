package link

import "strings"

templ tpl(props *Props) {
	<a
		if props.ID != "" {
			id={ props.ID }
		}
		class={ props.Class,
			templ.KV("cursor-pointer hover:shadow-xl", props.HXGet != "" || props.HXPost != "" || props.HXPut != "" || props.HXPatch != "" || props.HXDelete != "") }
		if props != nil {
			if props.Href != "" {
				href={ templ.SafeURL(props.Href) }
			}
			if len(props.HXTrigger) > 0 {
				hx-trigger={ strings.Join(props.HXTrigger, ",") }
			}
			if props.HXSwap != "" {
				hx-swap={ props.HXSwap.String() }
			}
			if props.HXTarget != "" {
				hx-target={ props.HXTarget }
			}
			if props.HXGet != "" {
				href={ templ.URL(props.HXGet) }
				hx-get={ props.HXGet }
			}
			if props.HXPost != "" {
				hx-post={ props.HXPost }
			}
			if props.HXPut != "" {
				hx-put={ props.HXPut }
			}
			if props.HXPatch != "" {
				hx-patch={ props.HXPatch }
			}
			if props.HXDelete != "" {
				hx-delete={ props.HXDelete }
			}
			if props.HXPushURL {
				hx-push-url="true"
			}
			if props.XOnTrigger != "" {
				x-on:htmx:trigger={ props.XOnTrigger }
			}
			if props.Target != "" {
				target={ props.Target }
			}
			if props.HXBoost != "" {
				hx-boost={ props.HXBoost }
			}
		}
	>
		if props.Icon != "" {
			// <span class="mr-2">
			<div class="flex items-center gap-1">
				@templ.Raw(props.Icon)
				<span>{ props.Title }</span>
			</div>
			// </span>
		} else {
			<span>{ props.Title }</span>
		}
		if props.Subtitle != "" {
			<span class="ml-2 text-sm text-gray-500">{ props.Subtitle }</span>
		}
		if props.Badge != nil {
			<span class="ml-2">
				@props.Badge
			</span>
		}
		{ children... }
		if len(props.Submenu) > 0 {
			<ul>
				for _, subitem := range props.Submenu {
					<li>
						@New(
							WithID(subitem.ID),
							WithHref(subitem.Href),
							WithTitle(subitem.Title),
							WithSubtitle(subitem.Subtitle),
							WithBadge(subitem.Badge),
							WithIcon(subitem.Icon),
							WithClass(subitem.Class),
							WithHXGet(subitem.HXGet),
							WithHXPost(subitem.HXPost),
							WithHXPut(subitem.HXPut),
							WithHXPatch(subitem.HXPatch),
							WithHXDelete(subitem.HXDelete),
							WithTarget(subitem.Target),
							WithHXSwap(subitem.HXSwap),
							WithHXTarget(subitem.HXTarget),
							WithHXTrigger(subitem.HXTrigger),
							WithHXPushURL(subitem.HXPushURL),
							WithXOnTrigger(subitem.XOnTrigger),
							WithHxBoost(subitem.HXBoost),
							WithSubmenu(subitem.Submenu...),
						)
					</li>
				}
			</ul>
		}
		if props.EndIcon != "" {
			<span class="ml-2">
				@templ.Raw(props.EndIcon)
			</span>
		}
	</a>
}
